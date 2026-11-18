library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HW2 is
    generic (
        CLK_FREQ_HZ    : integer := 100000000;
        PWM_FREQ_HZ    : integer := 1000;
        MAX_BRIGHTNESS : integer := 255
    );
    port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;  -- Active-high reset button (C)
        btn   : in  STD_LOGIC_VECTOR(3 downto 0); -- U, R, L, D
        led   : out STD_LOGIC
    );
end HW2;

architecture Behavioral of HW2 is
    constant PWM_DIV : integer :=
        CLK_FREQ_HZ / (PWM_FREQ_HZ * (MAX_BRIGHTNESS + 1));
    constant DB_DIV : integer := CLK_FREQ_HZ / 100; -- sample buttons every 10 ms

    -- Speed levels: 0 = slow (4 s/cycle), 1 = normal (2 s/cycle), 2 = fast (1 s/cycle)
    function step_div_for_speed(speed : integer) return integer is
    begin
        case speed is
            when 0      => return CLK_FREQ_HZ / 128;
            when 2      => return CLK_FREQ_HZ / 512;
            when others => return CLK_FREQ_HZ / 256;
        end case;
    end function;

    type breath_state_type is (UP, DOWN);
    signal breath_state : breath_state_type := UP;

    -- Modes: 0 = breathing, 1 = blinking, 2 = fade up and stay on
    signal mode        : integer range 0 to 2 := 0;
    signal speed_level : integer range 0 to 2 := 1;
    signal paused      : STD_LOGIC := '0';

    signal brightness  : integer range 0 to MAX_BRIGHTNESS := 0;
    signal blink_count : integer range 0 to MAX_BRIGHTNESS := 0;
    signal blink_on    : STD_LOGIC := '0';

    signal pwm_div_cnt : integer range 0 to PWM_DIV - 1 := 0;
    signal pwm_cnt     : integer range 0 to MAX_BRIGHTNESS := 0;
    signal step_cnt    : integer range 0 to CLK_FREQ_HZ / 128 := 0;

    -- Two-stage synchronizer and 10 ms button sampling/debounce
    signal btn_sync1   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal btn_sync2   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal btn_db      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal btn_db_prev : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal db_cnt      : integer range 0 to DB_DIV - 1 := 0;
    signal btn_press   : STD_LOGIC_VECTOR(3 downto 0);

begin
    btn_press <= btn_db and not btn_db_prev;

    process(clk, reset)
    begin
        if reset = '1' then
            btn_sync1 <= (others => '0');
            btn_sync2 <= (others => '0');
            btn_db    <= (others => '0');
            db_cnt    <= 0;
        elsif rising_edge(clk) then
            btn_sync1 <= btn;
            btn_sync2 <= btn_sync1;

            if db_cnt = DB_DIV - 1 then
                db_cnt <= 0;
                btn_db <= btn_sync2;
            else
                db_cnt <= db_cnt + 1;
            end if;
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            breath_state <= UP;
            mode         <= 0;
            speed_level  <= 1;
            paused       <= '0';
            brightness   <= 0;
            blink_count  <= 0;
            blink_on     <= '0';
            pwm_div_cnt  <= 0;
            pwm_cnt      <= 0;
            step_cnt     <= 0;
            btn_db_prev  <= (others => '0');

        elsif rising_edge(clk) then
            btn_db_prev <= btn_db;

            -- PWM runs continuously so LED brightness remains stable while paused.
            if pwm_div_cnt = PWM_DIV - 1 then
                pwm_div_cnt <= 0;
                if pwm_cnt = MAX_BRIGHTNESS then
                    pwm_cnt <= 0;
                else
                    pwm_cnt <= pwm_cnt + 1;
                end if;
            else
                pwm_div_cnt <= pwm_div_cnt + 1;
            end if;

            -- Button actions. Board buttons are active-high.
            if btn_press(0) = '1' then              -- U: next effect
                if mode = 2 then
                    mode <= 0;
                else
                    mode <= mode + 1;
                end if;
                brightness  <= 0;
                breath_state <= UP;
                blink_count <= 0;
                blink_on    <= '0';
                step_cnt    <= 0;

            elsif btn_press(1) = '1' then            -- R: faster
                if speed_level < 2 then
                    speed_level <= speed_level + 1;
                end if;
                step_cnt    <= 0;
                blink_count <= 0;

            elsif btn_press(2) = '1' then            -- L: slower
                if speed_level > 0 then
                    speed_level <= speed_level - 1;
                end if;
                step_cnt    <= 0;
                blink_count <= 0;

            elsif btn_press(3) = '1' then            -- D: pause / resume
                paused <= not paused;
            end if;

            -- Update animation at a speed-dependent rate.
            if paused = '0' and
               btn_press(0) = '0' and
               btn_press(1) = '0' and
               btn_press(2) = '0' then

                if step_cnt >= step_div_for_speed(speed_level) - 1 then
                    step_cnt <= 0;

                    case mode is
                        when 0 => -- Breathing: 0 -> max -> 0; default full cycle = 2 s
                            if breath_state = UP then
                                if brightness >= MAX_BRIGHTNESS then
                                    breath_state <= DOWN;
                                    if brightness > 0 then
                                        brightness <= brightness - 1;
                                    end if;
                                else
                                    brightness <= brightness + 1;
                                end if;
                            else
                                if brightness = 0 then
                                    breath_state <= UP;
                                    brightness <= brightness + 1;
                                else
                                    brightness <= brightness - 1;
                                end if;
                            end if;

                        when 1 => -- Blinking; default full on/off cycle = 2 s
                            if blink_count >= MAX_BRIGHTNESS then
                                blink_count <= 0;
                                blink_on <= not blink_on;
                                if blink_on = '0' then
                                    brightness <= MAX_BRIGHTNESS;
                                else
                                    brightness <= 0;
                                end if;
                            else
                                blink_count <= blink_count + 1;
                            end if;

                        when 2 => -- Fade from off to full brightness, then stay on
                            if brightness < MAX_BRIGHTNESS then
                                brightness <= brightness + 1;
                            else
                                brightness <= MAX_BRIGHTNESS;
                            end if;

                        when others =>
                            brightness <= 0;
                    end case;
                else
                    step_cnt <= step_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    process(pwm_cnt, brightness)
    begin
        if pwm_cnt < brightness then
            led <= '1';
        else
            led <= '0';
        end if;
    end process;

end Behavioral;
