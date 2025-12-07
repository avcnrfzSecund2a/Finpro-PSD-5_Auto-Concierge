library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DoorLock is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;        -- async reset, aktif '1'
        enable         : in  std_logic;        -- '1' saat input password diizinkan
        password_input : in  integer range 0 to 9999;
        open_door      : in  std_logic;        -- sensor pintu (1 = pintu terbuka)
        rst_m          : in  std_logic;        -- reset manual (misal tombol)
        unlock         : out std_logic;        -- kontrol aktuator doorlock
        lock_status    : out std_logic         -- '1' = terkunci, '0' = terbuka
    );
end entity DoorLock;

architecture Behavioral of DoorLock is

    constant correct_password : integer := 1234;   -- bisa diganti / di-update
    signal current_password   : integer := correct_password;

    type doorlock_state is (rst_pw, enter_a, enter_b, mode_enter, pw_correct, unlock_door);
    signal state : doorlock_state := rst_pw;

    signal door_locked : std_logic := '1';         -- '1' = terkunci

begin

    -- status lock dikeluarkan ke port
    lock_status <= door_locked;

    process(clk, rst)
    begin
        if rst = '1' then
            ----------------------------------------------------------
            -- Reset global: kembali ke state awal
            ----------------------------------------------------------
            state           <= rst_pw;
            current_password <= correct_password;
            door_locked     <= '1';
            unlock          <= '0';

        elsif rising_edge(clk) then
            ----------------------------------------------------------
            -- Default tiap clock
            ----------------------------------------------------------
            unlock <= '0';  -- default: tidak aktifkan motor pembuka

            case state is

                ------------------------------------------------------
                -- rst_pw: kondisi awal, pintu terkunci
                ------------------------------------------------------
                when rst_pw =>
                    door_locked <= '1';
                    if enable = '1' then
                        -- mulai proses input password baru / login
                        state <= enter_a;
                    else
                        state <= rst_pw;
                    end if;

                ------------------------------------------------------
                -- enter_a: simpan password_input sebagai current_password
                -- Bisa dimaknai: resepsionis / sistem memasukkan password baru
                ------------------------------------------------------
                when enter_a =>
                    if enable = '1' then
                        current_password <= password_input;
                        state            <= enter_b;
                    else
                        state <= enter_a;
                    end if;

                ------------------------------------------------------
                -- enter_b: cek kecocokan input dengan current_password
                ------------------------------------------------------
                when enter_b =>
                    if enable = '1' then
                        if password_input = current_password then
                            state <= mode_enter;
                        else
                            -- salah → kembali reset
                            state <= rst_pw;
                        end if;
                    end if;

                ------------------------------------------------------
                -- mode_enter: mode tunggu sampai user memasukkan
                -- password yang benar (correct_password)
                ------------------------------------------------------
                when mode_enter =>
                    if password_input = correct_password then
                        state <= pw_correct;
                    elsif rst_m = '1' then
                        -- reset manual dari petugas
                        state <= rst_pw;
                    else
                        state <= mode_enter;
                    end if;

                ------------------------------------------------------
                -- pw_correct: password benar, pintu boleh dibuka
                ------------------------------------------------------
                when pw_correct =>
                    if open_door = '1' then
                        -- motor/solenoid aktif membuka pintu
                        unlock      <= '1';
                        door_locked <= '0';
                        state       <= unlock_door;
                    elsif rst_m = '1' then
                        -- batal, kunci lagi
                        door_locked <= '1';
                        state       <= rst_pw;
                    else
                        -- menunggu pintu benar-benar dibuka
                        state <= pw_correct;
                    end if;

                ------------------------------------------------------
                -- unlock_door: pintu dalam keadaan terbuka
                ------------------------------------------------------
                when unlock_door =>
                    door_locked <= '0';
                    if open_door = '0' then
                        -- pintu ditutup kembali → kembali ke mode_enter
                        door_locked <= '1';
                        state       <= mode_enter;
                    else
                        state <= unlock_door;
                    end if;

            end case;
        end if;
    end process;

end architecture Behavioral;