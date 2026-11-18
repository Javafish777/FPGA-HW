library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.ALL;

-- HW3: EGO-XZ7 HDMI output using the on-board ADV7511.
-- Video timing: 640x480, 800x525 total, approximately 59.9 Hz.
-- ADV7511 input bus: 24-bit YCbCr 4:2:2, 12-bit components, Style 2.
entity HW3_HDMI_TOP is
    generic (
        -- Set TRUE only for the supplied testbench (uses a simple /4 clock).
        -- Keep FALSE for the physical EGO-XZ7 board (uses MMCM).
        G_SIMULATION               : boolean := false;
        G_I2C_STARTUP_WAIT_CYCLES  : positive := 25_000_000;
        G_I2C_HALF_PERIOD_CYCLES   : positive := 500;

        RED_X   : natural := 40;
        RED_Y   : natural := 80;
        RED_W   : positive := 160;
        RED_H   : positive := 120;
        GREEN_X : natural := 240;
        GREEN_Y : natural := 80;
        GREEN_W : positive := 160;
        GREEN_H : positive := 120;
        BLUE_X  : natural := 440;
        BLUE_Y  : natural := 80;
        BLUE_W  : positive := 160;
        BLUE_H  : positive := 120
    );
    port (
        CLK_100M : in  std_logic;
        BTNC     : in  std_logic; -- active-high reset

        HDMI_D     : out std_logic_vector(23 downto 0);
        HDMI_HSYNC : out std_logic;
        HDMI_VSYNC : out std_logic;
        HDMI_CLK   : out std_logic;
        HDMI_SCL   : inout std_logic;
        HDMI_SDA   : inout std_logic;
        HDMI_INT   : in  std_logic;

        LED0 : out std_logic; -- ADV7511 initialization complete
        LED1 : out std_logic  -- I2C initialization error
    );
end entity HW3_HDMI_TOP;

architecture RTL of HW3_HDMI_TOP is
    constant H_ACTIVE : integer := 640;
    constant H_FRONT  : integer := 16;
    constant H_SYNC   : integer := 96;
    constant H_BACK   : integer := 48;
    constant H_TOTAL  : integer := H_ACTIVE + H_FRONT + H_SYNC + H_BACK;

    constant V_ACTIVE : integer := 480;
    constant V_FRONT  : integer := 10;
    constant V_SYNC   : integer := 2;
    constant V_BACK   : integer := 33;
    constant V_TOTAL  : integer := V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    signal pixel_clk      : std_logic := '0';
    signal mmcm_locked    : std_logic := '0';
    signal video_reset    : std_logic;
    signal div_count      : unsigned(1 downto 0) := (others => '0');

    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;

    signal init_done : std_logic;
    signal init_err  : std_logic;

    function clamp8(value : integer) return integer is
    begin
        if value < 0 then
            return 0;
        elsif value > 255 then
            return 255;
        else
            return value;
        end if;
    end function;

    -- Return 24-bit RGB888 for a pixel.
    function pixel_rgb(x : integer; y : integer) return std_logic_vector is
        variable rgb : std_logic_vector(23 downto 0) := x"000000";
    begin
        if x >= RED_X and x < RED_X + RED_W and
           y >= RED_Y and y < RED_Y + RED_H then
            rgb := x"FF0000";
        elsif x >= GREEN_X and x < GREEN_X + GREEN_W and
              y >= GREEN_Y and y < GREEN_Y + GREEN_H then
            rgb := x"00FF00";
        elsif x >= BLUE_X and x < BLUE_X + BLUE_W and
              y >= BLUE_Y and y < BLUE_Y + BLUE_H then
            rgb := x"0000FF";
        end if;
        return rgb;
    end function;

    -- Return {Y[11:0], Cb[11:0], Cr[11:0]}.
    -- 8-bit limited-range BT.601 values are expanded to 12-bit by << 4.
    function rgb_to_ycbcr(rgb : std_logic_vector(23 downto 0))
        return std_logic_vector is
        variable r, g, b : integer;
        variable y8, cb8, cr8 : integer;
        variable result_value : std_logic_vector(35 downto 0);
    begin
        r := to_integer(unsigned(rgb(23 downto 16)));
        g := to_integer(unsigned(rgb(15 downto 8)));
        b := to_integer(unsigned(rgb(7 downto 0)));

        y8  := clamp8(16  + ( 66*r + 129*g +  25*b + 128) / 256);
        cb8 := clamp8(128 + (-38*r -  74*g + 112*b + 128) / 256);
        cr8 := clamp8(128 + (112*r -  94*g -  18*b + 128) / 256);

        result_value(35 downto 24) := std_logic_vector(to_unsigned(y8  * 16, 12));
        result_value(23 downto 12) := std_logic_vector(to_unsigned(cb8 * 16, 12));
        result_value(11 downto 0)  := std_logic_vector(to_unsigned(cr8 * 16, 12));
        return result_value;
    end function;

begin
    ------------------------------------------------------------------------
    -- Pixel clock generation.
    -- Hardware mode: MMCM makes 100 MHz * 10.125 / 40.25 = 25.1553 MHz,
    -- close to the 25.175 MHz 640x480 nominal pixel clock.
    -- Simulation mode: simple divide-by-4 behavioural clock.
    ------------------------------------------------------------------------
    gen_sim_clock : if G_SIMULATION generate
        process(CLK_100M)
        begin
            if rising_edge(CLK_100M) then
                if BTNC = '1' then
                    div_count <= (others => '0');
                    pixel_clk <= '0';
                else
                    if div_count = "01" then
                        div_count <= (others => '0');
                        pixel_clk <= not pixel_clk;
                    else
                        div_count <= div_count + 1;
                    end if;
                end if;
            end if;
        end process;
        mmcm_locked <= '1';
    end generate;

    gen_hw_clock : if not G_SIMULATION generate
        signal mmcm_clkout : std_logic;
        signal mmcm_fb     : std_logic;
        signal mmcm_fb_buf : std_logic;
    begin
        u_mmcm : MMCME2_BASE
            generic map (
                BANDWIDTH          => "OPTIMIZED",
                CLKFBOUT_MULT_F    => 10.125,
                CLKFBOUT_PHASE     => 0.0,
                CLKIN1_PERIOD      => 10.000,
                CLKOUT0_DIVIDE_F   => 40.250,
                CLKOUT0_DUTY_CYCLE => 0.500,
                CLKOUT0_PHASE      => 0.000,
                DIVCLK_DIVIDE      => 1,
                STARTUP_WAIT       => false
            )
            port map (
                CLKIN1    => CLK_100M,
                CLKFBIN   => mmcm_fb_buf,
                CLKFBOUT  => mmcm_fb,
                CLKFBOUTB => open,
                CLKOUT0   => mmcm_clkout,
                CLKOUT0B  => open,
                CLKOUT1   => open,
                CLKOUT2   => open,
                CLKOUT3   => open,
                CLKOUT4   => open,
                CLKOUT5   => open,
                CLKOUT6   => open,
                LOCKED    => mmcm_locked,
                PWRDWN    => '0',
                RST       => BTNC
            );

        u_fb_buf : BUFG
            port map (I => mmcm_fb, O => mmcm_fb_buf);

        u_pixel_buf : BUFG
            port map (I => mmcm_clkout, O => pixel_clk);
    end generate;

    video_reset <= BTNC or not mmcm_locked;
    HDMI_CLK <= pixel_clk;

    ------------------------------------------------------------------------
    -- Raster counters. Update on falling edge so the data and sync outputs
    -- settle before the ADV7511 samples them on the rising edge of HDMI_CLK.
    ------------------------------------------------------------------------
    process(pixel_clk)
    begin
        if falling_edge(pixel_clk) then
            if video_reset = '1' then
                h_count <= 0;
                v_count <= 0;
            else
                if h_count = H_TOTAL - 1 then
                    h_count <= 0;
                    if v_count = V_TOTAL - 1 then
                        v_count <= 0;
                    else
                        v_count <= v_count + 1;
                    end if;
                else
                    h_count <= h_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- Active-low 640x480 separate syncs.
    HDMI_HSYNC <= '0' when
        (h_count >= H_ACTIVE + H_FRONT and
         h_count < H_ACTIVE + H_FRONT + H_SYNC) else '1';

    HDMI_VSYNC <= '0' when
        (v_count >= V_ACTIVE + V_FRONT and
         v_count < V_ACTIVE + V_FRONT + V_SYNC) else '1';

    ------------------------------------------------------------------------
    -- ADV7511 Style-2 4:2:2 input:
    -- D[23:12] = Cb for even pixel / Cr for odd pixel.
    -- D[11:0]  = Y for the current pixel.
    -- Chroma is averaged over each adjacent two-pixel pair.
    ------------------------------------------------------------------------
    process(h_count, v_count)
        variable rgb_now, rgb_pair : std_logic_vector(23 downto 0);
        variable ycc_now, ycc_pair : std_logic_vector(35 downto 0);
        variable luma, chroma : unsigned(11 downto 0);
        variable cb_sum, cr_sum : integer;
        variable pair_x : integer;
    begin
        -- Limited-range digital black in 12-bit form.
        luma   := to_unsigned(16 * 16, 12);
        chroma := to_unsigned(128 * 16, 12);

        if h_count < H_ACTIVE and v_count < V_ACTIVE then
            rgb_now := pixel_rgb(h_count, v_count);
            ycc_now := rgb_to_ycbcr(rgb_now);
            luma := unsigned(ycc_now(35 downto 24));

            if (h_count mod 2) = 0 then
                -- First pixel of the pair: send averaged Cb.
                pair_x := h_count + 1;
                if pair_x < H_ACTIVE then
                    rgb_pair := pixel_rgb(pair_x, v_count);
                    ycc_pair := rgb_to_ycbcr(rgb_pair);
                    cb_sum := to_integer(unsigned(ycc_now(23 downto 12))) +
                              to_integer(unsigned(ycc_pair(23 downto 12)));
                    chroma := to_unsigned(cb_sum / 2, 12);
                else
                    chroma := unsigned(ycc_now(23 downto 12));
                end if;
            else
                -- Second pixel of the pair: send averaged Cr.
                pair_x := h_count - 1;
                rgb_pair := pixel_rgb(pair_x, v_count);
                ycc_pair := rgb_to_ycbcr(rgb_pair);
                cr_sum := to_integer(unsigned(ycc_pair(11 downto 0))) +
                          to_integer(unsigned(ycc_now(11 downto 0)));
                chroma := to_unsigned(cr_sum / 2, 12);
            end if;
        end if;

        HDMI_D(23 downto 12) <= std_logic_vector(chroma);
        HDMI_D(11 downto 0)  <= std_logic_vector(luma);
    end process;

    ------------------------------------------------------------------------
    -- Initialize the on-board ADV7511 through its I2C control port.
    ------------------------------------------------------------------------
    u_adv7511_init : entity work.ADV7511_INIT
        generic map (
            G_STARTUP_WAIT_CYCLES => G_I2C_STARTUP_WAIT_CYCLES,
            G_I2C_HALF_PERIOD     => G_I2C_HALF_PERIOD_CYCLES
        )
        port map (
            CLK_100M  => CLK_100M,
            RESET     => BTNC,
            HDMI_SCL  => HDMI_SCL,
            HDMI_SDA  => HDMI_SDA,
            INIT_DONE => init_done,
            INIT_ERR  => init_err
        );

    LED0 <= init_done;
    LED1 <= init_err;

    -- HDMI_INT is provided by the board but not required in this
    -- simple fixed-mode initialization sequence.
end architecture RTL;
