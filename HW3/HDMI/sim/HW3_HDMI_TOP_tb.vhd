library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HW3_HDMI_TOP_tb is
end entity;

architecture SIM of HW3_HDMI_TOP_tb is
    signal clk_100m : std_logic := '0';
    signal btnc     : std_logic := '1';

    signal hdmi_d     : std_logic_vector(23 downto 0);
    signal hdmi_hsync : std_logic;
    signal hdmi_vsync : std_logic;
    signal hdmi_clk   : std_logic;
    signal hdmi_scl   : std_logic;
    signal hdmi_sda   : std_logic;
    signal hdmi_int   : std_logic := '1';
    signal led0       : std_logic;
    signal led1       : std_logic;
begin
    clk_100m <= not clk_100m after 5 ns;

    -- Weak pull-ups model the board's I2C pull-up resistors.
    hdmi_scl <= 'H';
    hdmi_sda <= 'H';

    DUT : entity work.HW3_HDMI_TOP
        generic map (
            G_SIMULATION              => true,
            G_I2C_STARTUP_WAIT_CYCLES => 25_000_000,
            G_I2C_HALF_PERIOD_CYCLES  => 500
        )
        port map (
            CLK_100M   => clk_100m,
            BTNC       => btnc,
            HDMI_D     => hdmi_d,
            HDMI_HSYNC => hdmi_hsync,
            HDMI_VSYNC => hdmi_vsync,
            HDMI_CLK   => hdmi_clk,
            HDMI_SCL   => hdmi_scl,
            HDMI_SDA   => hdmi_sda,
            HDMI_INT   => hdmi_int,
            LED0       => led0,
            LED1       => led1
        );

    stimulus : process
    begin
        wait for 200 ns;
        btnc <= '0';

        -- Allow the raster to run through the first several scan lines.
        wait for 3 ms;

        assert (hdmi_hsync = '0' or hdmi_hsync = '1')
            report "HSYNC is not a defined logic level" severity error;
        assert (hdmi_vsync = '0' or hdmi_vsync = '1')
            report "VSYNC is not a defined logic level" severity error;
        assert (hdmi_clk = '0' or hdmi_clk = '1')
            report "HDMI pixel clock is not a defined logic level" severity error;

        for i in hdmi_d'range loop
            assert (hdmi_d(i) = '0' or hdmi_d(i) = '1')
                report "HDMI data bus contains an unknown bit" severity error;
        end loop;

        report "HDMI raster/data simulation checks completed." severity note;
        wait;
    end process;
end architecture SIM;
