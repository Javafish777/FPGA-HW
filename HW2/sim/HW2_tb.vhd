library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HW2_tb is
end HW2_tb;

architecture sim of HW2_tb is
    signal clk   : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '0';
    signal btn   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal led   : STD_LOGIC;

begin
    clk <= not clk after 5 ns;

    -- Use a small simulated clock frequency so the animation can be tested quickly.
    uut: entity work.HW2
        generic map (
            CLK_FREQ_HZ    => 1024,
            PWM_FREQ_HZ    => 1,
            MAX_BRIGHTNESS => 255
        )
        port map (
            clk   => clk,
            reset => reset,
            btn   => btn,
            led   => led
        );

    stim_proc: process
    begin
        reset <= '1';
        wait for 40 ns;
        reset <= '0';
        wait for 200 ns;

        -- U: switch from breathing to blinking
        btn(0) <= '1';
        wait for 200 ns;
        btn(0) <= '0';
        wait for 200 ns;

        -- R: faster
        btn(1) <= '1';
        wait for 200 ns;
        btn(1) <= '0';
        wait for 200 ns;

        -- D: pause, then resume
        btn(3) <= '1';
        wait for 200 ns;
        btn(3) <= '0';
        wait for 200 ns;
        btn(3) <= '1';
        wait for 200 ns;
        btn(3) <= '0';

        wait for 2 us;
        assert false report "Simulation finished" severity failure;
    end process;
end sim;
