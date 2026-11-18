library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- HW3: VGA 640x480, three 1-bit RGB colour blocks.
-- Clock input: 100 MHz. Pixel enable: 25 MHz.
entity HW3_VGA is
    generic (
        H_RES   : positive := 640;
        H_FP    : positive := 16;
        H_SYNC  : positive := 96;
        H_BP    : positive := 48;
        V_RES   : positive := 480;
        V_FP    : positive := 10;
        V_SYNC  : positive := 2;
        V_BP    : positive := 33;

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
        video_clk : in  std_logic; -- 100 MHz board clock
        rst       : in  std_logic; -- active-high reset

        VGA_HSYNC : out std_logic;
        VGA_VSYNC : out std_logic;
        VGA_R     : out std_logic;
        VGA_G     : out std_logic;
        VGA_B     : out std_logic
    );
end entity HW3_VGA;

architecture RTL of HW3_VGA is
    constant H_TOTAL : positive := H_RES + H_FP + H_SYNC + H_BP;
    constant V_TOTAL : positive := V_RES + V_FP + V_SYNC + V_BP;

    signal div_count : unsigned(1 downto 0) := (others => '0');
    signal pixel_ce  : std_logic := '0';

    signal h_count : natural range 0 to H_TOTAL - 1 := 0;
    signal v_count : natural range 0 to V_TOTAL - 1 := 0;

    signal video_active : std_logic;
    signal red_area     : std_logic;
    signal green_area   : std_logic;
    signal blue_area    : std_logic;
begin

    -- Generate one pixel-update enable pulse every four 100 MHz clocks.
    -- The design remains in one clock domain; no generated clock is used.
    process(video_clk)
    begin
        if rising_edge(video_clk) then
            if rst = '1' then
                div_count <= (others => '0');
                pixel_ce  <= '0';
            else
                div_count <= div_count + 1;
                if div_count = "11" then
                    pixel_ce <= '1';
                else
                    pixel_ce <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Horizontal and vertical scan counters.
    process(video_clk)
    begin
        if rising_edge(video_clk) then
            if rst = '1' then
                h_count <= 0;
                v_count <= 0;
            elsif pixel_ce = '1' then
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

    -- 640x480 VGA timing: negative HSYNC and VSYNC polarity.
    VGA_HSYNC <= '0' when
        (h_count >= H_RES + H_FP and
         h_count < H_RES + H_FP + H_SYNC) else '1';

    VGA_VSYNC <= '0' when
        (v_count >= V_RES + V_FP and
         v_count < V_RES + V_FP + V_SYNC) else '1';

    video_active <= '1' when
        (h_count < H_RES and v_count < V_RES) else '0';

    red_area <= '1' when
        (h_count >= RED_X and h_count < RED_X + RED_W and
         v_count >= RED_Y and v_count < RED_Y + RED_H) else '0';

    green_area <= '1' when
        (h_count >= GREEN_X and h_count < GREEN_X + GREEN_W and
         v_count >= GREEN_Y and v_count < GREEN_Y + GREEN_H) else '0';

    blue_area <= '1' when
        (h_count >= BLUE_X and h_count < BLUE_X + BLUE_W and
         v_count >= BLUE_Y and v_count < BLUE_Y + BLUE_H) else '0';

    -- Three independent 1-bit colour outputs.
    -- Overlap is allowed and can produce secondary colours.
    VGA_R <= '1' when video_active = '1' and red_area = '1' else '0';
    VGA_G <= '1' when video_active = '1' and green_area = '1' else '0';
    VGA_B <= '1' when video_active = '1' and blue_area = '1' else '0';

end architecture RTL;
