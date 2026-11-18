library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HW3 is
    port (
        video_clk : in  std_logic; -- 100 MHz clock
        rst       : in  std_logic; -- active-high reset

        hsync     : out std_logic;
        vsync     : out std_logic;

        r_out     : out std_logic_vector(3 downto 0);
        g_out     : out std_logic_vector(3 downto 0);
        b_out     : out std_logic_vector(3 downto 0)
    );
end entity HW3;

architecture RTL of HW3 is

    -- 640x480 @ approximately 60 Hz VGA timing
    -- Pixel clock = 25 MHz, obtained by dividing 100 MHz by 4.
    constant H_VISIBLE : integer := 640;
    constant H_FRONT   : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BACK    : integer := 48;
    constant H_TOTAL   : integer := H_VISIBLE + H_FRONT + H_SYNC + H_BACK; -- 800

    constant V_VISIBLE : integer := 480;
    constant V_FRONT   : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BACK    : integer := 33;
    constant V_TOTAL   : integer := V_VISIBLE + V_FRONT + V_SYNC + V_BACK; -- 525

    signal pix_div : unsigned(1 downto 0) := (others => '0');
    signal pixel_tick : std_logic := '0';

    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;

    signal video_active : std_logic;
    signal r_int : std_logic_vector(3 downto 0);
    signal g_int : std_logic_vector(3 downto 0);
    signal b_int : std_logic_vector(3 downto 0);

begin

    --------------------------------------------------------------------
    -- Divide 100 MHz clock by 4 to create a 25 MHz pixel enable.
    -- Keep all logic in the 100 MHz clock domain.
    --------------------------------------------------------------------
    process(video_clk)
    begin
        if rising_edge(video_clk) then
            if rst = '1' then
                pix_div    <= (others => '0');
                pixel_tick <= '0';
            else
                if pix_div = "11" then
                    pix_div    <= (others => '0');
                    pixel_tick <= '1';
                else
                    pix_div    <= pix_div + 1;
                    pixel_tick <= '0';
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Horizontal and vertical pixel counters
    --------------------------------------------------------------------
    process(video_clk)
    begin
        if rising_edge(video_clk) then
            if rst = '1' then
                h_count <= 0;
                v_count <= 0;
            elsif pixel_tick = '1' then
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

    --------------------------------------------------------------------
    -- VGA sync signals (640x480 standard timing uses active-low sync)
    --------------------------------------------------------------------
    hsync <= '0' when
        (h_count >= H_VISIBLE + H_FRONT) and
        (h_count <  H_VISIBLE + H_FRONT + H_SYNC)
        else '1';

    vsync <= '0' when
        (v_count >= V_VISIBLE + V_FRONT) and
        (v_count <  V_VISIBLE + V_FRONT + V_SYNC)
        else '1';

    video_active <= '1' when
        (h_count < H_VISIBLE) and
        (v_count < V_VISIBLE)
        else '0';

    --------------------------------------------------------------------
    -- Three colored blocks.
    -- Coordinates are within the 640x480 active display area.
    -- Red block:   x=60..219,  y=100..259
    -- Green block: x=240..399, y=100..259
    -- Blue block:  x=420..579, y=100..259
    --------------------------------------------------------------------
    process(h_count, v_count, video_active)
    begin
        r_int <= (others => '0');
        g_int <= (others => '0');
        b_int <= (others => '0');

        if video_active = '1' then
            if (h_count >= 60 and h_count < 220) and
               (v_count >= 100 and v_count < 260) then
                r_int <= "1111"; -- red
            elsif (h_count >= 240 and h_count < 400) and
                  (v_count >= 100 and v_count < 260) then
                g_int <= "1111"; -- green
            elsif (h_count >= 420 and h_count < 580) and
                  (v_count >= 100 and v_count < 260) then
                b_int <= "1111"; -- blue
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Board wiring note in the supplied XDC says physical R/B are swapped.
    -- Swap the red and blue output buses here to compensate.
    --------------------------------------------------------------------
    r_out <= b_int;
    g_out <= g_int;
    b_out <= r_int;

end architecture RTL;
