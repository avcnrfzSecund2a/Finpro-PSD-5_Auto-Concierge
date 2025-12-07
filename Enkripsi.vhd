library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Enkripsi_Dekripsi is
    port (
        inp   : in  integer range 0 to 1048575; -- 20 bit max
        START : in  std_logic;
        MODE  : in  std_logic;                 -- '0' = enkripsi, '1' = dekripsi
        KEY   : in  std_logic_vector(3 downto 0);
        CLK   : in  std_logic;
        DONE  : out std_logic;                 -- '1' saat hasil siap
        outp  : out integer
    );
end entity Enkripsi_Dekripsi;

architecture rtl of Enkripsi_Dekripsi is

    -- Data internal 20-bit
    signal INPUT_vec : std_logic_vector(19 downto 0);
    signal temp_reg  : std_logic_vector(19 downto 0) := (others => '0');
    signal temp_next : std_logic_vector(19 downto 0) := (others => '0');

    -- FSM state
    type state is (init, add_s, s_xor, swap_s, sub_s, done_s);
    signal present_state, next_state : state := init;

begin

    ------------------------------------------------------------------
    -- Kombinasi: next_state dan temp_next
    ------------------------------------------------------------------
    process(present_state, START, MODE, KEY, inp, temp_reg)
        variable result : std_logic_vector(19 downto 0);
        variable key_ext : std_logic_vector(19 downto 0);
    begin
        -- default
        result  := temp_reg;
        DONE    <= '0';

        -- konversi input integer ke 20-bit
        INPUT_vec <= std_logic_vector(to_unsigned(inp, 20));

        -- perpanjangan KEY jadi 20-bit (5 nibble)
        key_ext := KEY & KEY & KEY & KEY & KEY;

        case present_state is

            ----------------------------------------------------------
            -- init: tunggu START; saat START=1, muat INPUT dan lanjut
            ----------------------------------------------------------
            when init =>
                if START = '1' then
                    result     := INPUT_vec;
                    next_state <= add_s;
                else
                    next_state <= init;
                end if;

            ----------------------------------------------------------
            -- add_s: operasi penjumlahan per nibble (4 bit)
            -- sama seperti kode kamu
            ----------------------------------------------------------
            when add_s =>
                result := std_logic_vector(
                              unsigned(temp_reg(19 downto 16)) + unsigned(KEY)
                          ) &
                          std_logic_vector(
                              unsigned(temp_reg(15 downto 12)) + unsigned(KEY)
                          ) &
                          std_logic_vector(
                              unsigned(temp_reg(11 downto 8)) + unsigned(KEY)
                          ) &
                          std_logic_vector(
                              unsigned(temp_reg(7 downto 4)) + unsigned(KEY)
                          ) &
                          std_logic_vector(
                              unsigned(temp_reg(3 downto 0)) + unsigned(KEY)
                          );

                if MODE = '0' then             -- enkripsi
                    next_state <= s_xor;
                else                           -- dekripsi
                    next_state <= swap_s;
                end if;

            ----------------------------------------------------------
            -- s_xor: XOR dengan key_ext
            ----------------------------------------------------------
            when s_xor =>
                result := temp_reg xor key_ext;

                if MODE = '0' then
                    next_state <= swap_s;
                else
                    next_state <= sub_s;
                end if;

            ----------------------------------------------------------
            -- swap_s: swap 10 bit atas & 10 bit bawah
            ----------------------------------------------------------
            when swap_s =>
                result := temp_reg(9 downto 0) & temp_reg(19 downto 10);

                if MODE = '0' then
                    next_state <= sub_s;
                else
                    next_state <= s_xor;
                end if;

            ----------------------------------------------------------
            -- sub_s: pengurangan per nibble
            ----------------------------------------------------------
            when sub_s =>
                result := std_logic_vector(
                              unsigned(temp_reg(19 downto 16)) - unsigned(KEY)
                          ) &
                          std_logic_vector(
                              unsigned(temp_reg(15 downto 12)) - unsigned(KEY)
                          ) &
                          std_logic_vector(
                              unsigned(temp_reg(11 downto 8)) - unsigned(KEY)
                          ) &
                          std_logic_vector(
                              unsigned(temp_reg(7 downto 4)) - unsigned(KEY)
                          ) &
                          std_logic_vector(
                              unsigned(temp_reg(3 downto 0)) - unsigned(KEY)
                          );
                next_state <= done_s;

            ----------------------------------------------------------
            -- done_s: hasil sudah siap, DONE='1'
            ----------------------------------------------------------
            when done_s =>
                DONE <= '1';
                -- balik ke init saat START sudah dilepas
                if START = '0' then
                    next_state <= init;
                else
                    next_state <= done_s;
                end if;

        end case;

        temp_next <= result;
    end process;

    ------------------------------------------------------------------
    -- Register state & temp_reg (sinkron clock)
    ------------------------------------------------------------------
    process (CLK)
    begin
        if rising_edge(CLK) then
            present_state <= next_state;
            temp_reg      <= temp_next;
        end if;
    end process;

    -- Konversi hasil jadi integer
    outp <= to_integer(unsigned(temp_reg));

end architecture rtl;