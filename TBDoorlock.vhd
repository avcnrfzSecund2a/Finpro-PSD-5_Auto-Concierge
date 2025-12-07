library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_DoorLock is
end entity tb_DoorLock;

architecture sim of tb_DoorLock is

    -- Sinyal ke DUT
    signal clk_tb            : std_logic := '0';
    signal rst_tb            : std_logic := '0';
    signal enable_tb         : std_logic := '0';
    signal password_input_tb : integer range 0 to 9999 := 0;
    signal open_door_tb      : std_logic := '0';
    signal rst_m_tb          : std_logic := '0';
    signal unlock_tb         : std_logic;
    signal lock_status_tb    : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    --------------------------------------------------------------------
    -- Clock generator
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    --------------------------------------------------------------------
    -- Instansiasi DUT DoorLock
    --------------------------------------------------------------------
    dut_door : entity work.DoorLock
        port map (
            clk            => clk_tb,
            rst            => rst_tb,
            enable         => enable_tb,
            password_input => password_input_tb,
            open_door      => open_door_tb,
            rst_m          => rst_m_tb,
            unlock         => unlock_tb,
            lock_status    => lock_status_tb
        );

    --------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------
    stim_proc : process
    begin
        ----------------------------------------------------------------
        -- 1. Reset sistem
        ----------------------------------------------------------------
        rst_tb <= '1';
        enable_tb <= '0';
        password_input_tb <= 0;
        open_door_tb <= '0';
        rst_m_tb <= '0';

        wait for 5*CLK_PERIOD;
        rst_tb <= '0';
        report "Reset selesai, masuk state rst_pw";

        ----------------------------------------------------------------
        -- 2. Masuk ke enter_a dan enter_b (set current_password)
        ----------------------------------------------------------------
        wait for 2*CLK_PERIOD;
        enable_tb <= '1';
        password_input_tb <= 9999;  -- misalnya set current_password = 9999

        report "Set current_password ke 9999 (enter_a -> enter_b)";
        wait for 5*CLK_PERIOD; -- biarkan FSM jalan beberapa cycle

        ----------------------------------------------------------------
        -- 3. Di mode_enter: coba password SALAH dulu
        ----------------------------------------------------------------
        report "Coba password SALAH (1111)";
        password_input_tb <= 1111;
        wait for 5*CLK_PERIOD;

        ----------------------------------------------------------------
        -- 4. Masukkan password BENAR (default correct_password = 1234)
        ----------------------------------------------------------------
        report "Coba password BENAR (1234)";
        password_input_tb <= 1234;
        wait for 5*CLK_PERIOD;  -- FSM harus masuk ke pw_correct

        ----------------------------------------------------------------
        -- 5. Simulasikan pintu dibuka (open_door = '1')
        ----------------------------------------------------------------
        report "Simulasikan pintu DIBUKA (open_door = '1')";
        open_door_tb <= '1';
        wait for 5*CLK_PERIOD;

        ----------------------------------------------------------------
        -- 6. Pintu ditutup kembali (open_door = '0')
        ----------------------------------------------------------------
        report "Simulasikan pintu DITUTUP (open_door = '0')";
        open_door_tb <= '0';
        wait for 5*CLK_PERIOD;

        ----------------------------------------------------------------
        -- 7. Reset manual dari petugas (rst_m = '1')
        ----------------------------------------------------------------
        report "Reset manual (rst_m = '1')";
        rst_m_tb <= '1';
        wait for 2*CLK_PERIOD;
        rst_m_tb <= '0';

        ----------------------------------------------------------------
        -- Selesai simulasi
        ----------------------------------------------------------------
        wait for 10*CLK_PERIOD;
        report "Simulasi DoorLock selesai" severity note;
        wait;
    end process;

end architecture sim;