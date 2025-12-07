library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_Enkripsi_Dekripsi is
end entity tb_Enkripsi_Dekripsi;

architecture sim of tb_Enkripsi_Dekripsi is

    -- Sinyal untuk menghubungkan ke DUT
    signal clk_tb   : std_logic := '0';
    signal start_tb : std_logic := '0';
    signal mode_tb  : std_logic := '0';
    signal key_tb   : std_logic_vector(3 downto 0) := (others => '0');
    signal done_tb  : std_logic;
    signal inp_tb   : integer range 0 to 1048575 := 0;
    signal outp_tb  : integer;

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
    -- Instansiasi Device Under Test (DUT)
    --------------------------------------------------------------------
    dut_enc : entity work.Enkripsi_Dekripsi
        port map (
            inp   => inp_tb,
            START => start_tb,
            MODE  => mode_tb,
            KEY   => key_tb,
            CLK   => clk_tb,
            DONE  => done_tb,
            outp  => outp_tb
        );

    --------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------
    stim_proc : process
    begin
        -- Inisialisasi
        key_tb  <= "0011";   -- contoh key = 3
        mode_tb <= '0';      -- enkripsi
        inp_tb  <= 12345;    -- data awal

        start_tb <= '0';
        wait for 5*CLK_PERIOD;

        ----------------------------------------------------------------
        -- Tahap 1: Enkripsi
        ----------------------------------------------------------------
        report "Mulai ENKRIPSI";
        start_tb <= '1';
        wait for CLK_PERIOD;
        start_tb <= '0'; -- lepaskan START

        -- Tunggu sampai DONE = '1'
        wait until done_tb = '1';
        report "Enkripsi selesai. outp_tb = " & integer'image(outp_tb);

        ----------------------------------------------------------------
        -- Tahap 2: Dekripsi (pakai hasil enkripsi sebagai input)
        ----------------------------------------------------------------
        wait for 5*CLK_PERIOD;
        report "Mulai DEKRIPSI";

        mode_tb <= '1';      -- dekripsi
        inp_tb  <= outp_tb;  -- masukkan ciphertext sebagai input

        start_tb <= '1';
        wait for CLK_PERIOD;
        start_tb <= '0';

        wait until done_tb = '1';
        report "Dekripsi selesai. outp_tb (plaintext) = " & integer'image(outp_tb);

        ----------------------------------------------------------------
        -- Selesai simulasi
        ----------------------------------------------------------------
        wait for 10*CLK_PERIOD;
        report "Simulasi Enkripsi_Dekripsi selesai" severity note;
        wait;
    end process;

end architecture sim;