library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ADV7511 main-register I2C initializer for EGO-XZ7.
-- I2C is open-drain: the FPGA drives only LOW or releases the line ('Z').
entity ADV7511_INIT is
    generic (
        G_STARTUP_WAIT_CYCLES : positive := 25_000_000; -- 250 ms at 100 MHz
        G_I2C_HALF_PERIOD     : positive := 500         -- 5 us at 100 MHz
    );
    port (
        CLK_100M  : in    std_logic;
        RESET     : in    std_logic;
        HDMI_SCL  : inout std_logic;
        HDMI_SDA  : inout std_logic;
        INIT_DONE : out   std_logic;
        INIT_ERR  : out   std_logic
    );
end entity ADV7511_INIT;

architecture RTL of ADV7511_INIT is
    type reg_pair_t is record
        address : std_logic_vector(7 downto 0);
        data    : std_logic_vector(7 downto 0);
    end record;

    type reg_table_t is array (natural range <>) of reg_pair_t;

    -- ADV7511 setup:
    --  * power up and mandatory fixed registers
    --  * 24-bit YCbCr 4:2:2 input, 12 bits per component, Style 2
    --  * internal DE generator for 640x480
    --  * HDMI mode and VGA VIC #1
    constant INIT_TABLE : reg_table_t(0 to 21) := (
        0  => (x"41", x"10"),
        1  => (x"98", x"03"),
        2  => (x"9A", x"E0"),
        3  => (x"9C", x"30"),
        4  => (x"9D", x"01"),
        5  => (x"A2", x"A4"),
        6  => (x"A3", x"A4"),
        7  => (x"E0", x"D0"),
        8  => (x"F9", x"00"),
        9  => (x"15", x"01"),
        10 => (x"16", x"24"),
        11 => (x"48", x"08"),
        12 => (x"18", x"80"),
        13 => (x"17", x"61"), -- DE generator + active-low HSYNC/VSYNC
        14 => (x"35", x"8F"),
        15 => (x"36", x"23"),
        16 => (x"37", x"05"),
        17 => (x"38", x"00"),
        18 => (x"39", x"1E"),
        19 => (x"3A", x"00"),
        20 => (x"3C", x"01"),
        21 => (x"AF", x"02")
    );

    type state_t is (
        WAIT_POWER,
        START_IDLE, START_CONDITION, START_CLOCK_LOW,
        BIT_SETUP, BIT_RISE, BIT_FALL,
        ACK_SETUP, ACK_RISE, ACK_SAMPLE,
        STOP_SETUP, STOP_RISE, STOP_RELEASE,
        COMPLETE, FAILED
    );

    signal state          : state_t := WAIT_POWER;
    signal wait_count     : natural range 0 to G_STARTUP_WAIT_CYCLES := 0;
    signal half_count     : natural range 0 to G_I2C_HALF_PERIOD - 1 := 0;
    signal reg_index      : natural range 0 to INIT_TABLE'high := 0;
    signal byte_index     : natural range 0 to 2 := 0;
    signal bit_index      : natural range 0 to 7 := 7;
    signal tx_byte        : std_logic_vector(7 downto 0) := (others => '0');

    signal device_address : std_logic_vector(7 downto 0) := x"72";
    signal tried_alt_addr : std_logic := '0';
    signal retry_address  : std_logic := '0';
    signal stop_with_error: std_logic := '0';

    signal scl_drive_low  : std_logic := '0';
    signal sda_drive_low  : std_logic := '0';
    signal init_done_i    : std_logic := '0';
    signal init_err_i     : std_logic := '0';
begin
    -- Open-drain outputs. Board-level pull-ups are required.
    HDMI_SCL <= '0' when scl_drive_low = '1' else 'Z';
    HDMI_SDA <= '0' when sda_drive_low = '1' else 'Z';

    INIT_DONE <= init_done_i;
    INIT_ERR  <= init_err_i;

    process(CLK_100M)
    begin
        if rising_edge(CLK_100M) then
            if RESET = '1' then
                state           <= WAIT_POWER;
                wait_count      <= 0;
                half_count      <= 0;
                reg_index       <= 0;
                byte_index      <= 0;
                bit_index       <= 7;
                tx_byte         <= (others => '0');
                device_address  <= x"72"; -- 7-bit address 0x39 + write bit
                tried_alt_addr  <= '0';
                retry_address   <= '0';
                stop_with_error <= '0';
                scl_drive_low   <= '0';
                sda_drive_low   <= '0';
                init_done_i     <= '0';
                init_err_i      <= '0';
            elsif state = WAIT_POWER then
                if wait_count < G_STARTUP_WAIT_CYCLES then
                    wait_count <= wait_count + 1;
                else
                    state <= START_IDLE;
                end if;
            elsif state = COMPLETE or state = FAILED then
                null;
            else
                if half_count = G_I2C_HALF_PERIOD - 1 then
                    half_count <= 0;
                    case state is
                        when START_IDLE =>
                            scl_drive_low <= '0';
                            sda_drive_low <= '0';
                            state <= START_CONDITION;

                        when START_CONDITION =>
                            -- SDA falls while SCL is high: I2C START.
                            scl_drive_low <= '0';
                            sda_drive_low <= '1';
                            state <= START_CLOCK_LOW;

                        when START_CLOCK_LOW =>
                            scl_drive_low <= '1';
                            sda_drive_low <= '1';
                            byte_index <= 0;
                            bit_index <= 7;
                            tx_byte <= device_address;
                            state <= BIT_SETUP;

                        when BIT_SETUP =>
                            scl_drive_low <= '1';
                            if tx_byte(bit_index) = '0' then
                                sda_drive_low <= '1';
                            else
                                sda_drive_low <= '0';
                            end if;
                            state <= BIT_RISE;

                        when BIT_RISE =>
                            scl_drive_low <= '0';
                            state <= BIT_FALL;

                        when BIT_FALL =>
                            scl_drive_low <= '1';
                            if bit_index = 0 then
                                sda_drive_low <= '0'; -- release for ACK
                                state <= ACK_SETUP;
                            else
                                bit_index <= bit_index - 1;
                                state <= BIT_SETUP;
                            end if;

                        when ACK_SETUP =>
                            scl_drive_low <= '1';
                            sda_drive_low <= '0';
                            state <= ACK_RISE;

                        when ACK_RISE =>
                            scl_drive_low <= '0';
                            state <= ACK_SAMPLE;

                        when ACK_SAMPLE =>
                            -- Sample the slave while SCL is high.
                            scl_drive_low <= '1';
                            if HDMI_SDA = '0' then
                                if byte_index = 0 then
                                    byte_index <= 1;
                                    bit_index <= 7;
                                    tx_byte <= INIT_TABLE(reg_index).address;
                                    state <= BIT_SETUP;
                                elsif byte_index = 1 then
                                    byte_index <= 2;
                                    bit_index <= 7;
                                    tx_byte <= INIT_TABLE(reg_index).data;
                                    state <= BIT_SETUP;
                                else
                                    state <= STOP_SETUP;
                                end if;
                            else
                                -- The strap pin selects 0x72 or 0x7A.
                                -- Try the alternate address once on the first
                                -- address-byte NACK, then stop on any error.
                                if byte_index = 0 and reg_index = 0 and
                                   tried_alt_addr = '0' then
                                    tried_alt_addr <= '1';
                                    retry_address <= '1';
                                    state <= STOP_SETUP;
                                else
                                    stop_with_error <= '1';
                                    state <= STOP_SETUP;
                                end if;
                            end if;

                        when STOP_SETUP =>
                            scl_drive_low <= '1';
                            sda_drive_low <= '1';
                            state <= STOP_RISE;

                        when STOP_RISE =>
                            scl_drive_low <= '0';
                            sda_drive_low <= '1';
                            state <= STOP_RELEASE;

                        when STOP_RELEASE =>
                            -- SDA rises while SCL is high: I2C STOP.
                            scl_drive_low <= '0';
                            sda_drive_low <= '0';
                            if stop_with_error = '1' then
                                init_err_i <= '1';
                                state <= FAILED;
                            elsif retry_address = '1' then
                                retry_address <= '0';
                                device_address <= x"7A"; -- 7-bit address 0x3D + write bit
                                state <= START_IDLE;
                            elsif reg_index = INIT_TABLE'high then
                                init_done_i <= '1';
                                state <= COMPLETE;
                            else
                                reg_index <= reg_index + 1;
                                state <= START_IDLE;
                            end if;

                        when others =>
                            state <= FAILED;
                            init_err_i <= '1';
                    end case;
                else
                    half_count <= half_count + 1;
                end if;
            end if;
        end if;
    end process;
end architecture RTL;
