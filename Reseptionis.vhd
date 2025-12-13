library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Receptionist_Hotel_Automatic is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;

        -- ===== INPUT DARI APLIKASI RESEPSIONIS =====
        start_input : in  std_logic;             -- tombol submit data
        guest_name  : in  std_logic_vector(7 downto 0); -- ID / nama singkat
        stay_days   : in  integer range 1 to 30;
        username_in : in  integer range 0 to 9999;
        password_in : in  integer range 0 to 9999;

        -- ===== OUTPUT KE SISTEM KEAMANAN =====
        enc_password : out integer;              -- password terenkripsi
        auth_enable  : out std_logic;             -- izin akses kamar
        valid_user   : out std_logic              -- status otentikasi
    );
end entity Receptionist_Hotel_Automatic;

architecture Behavioral of Receptionist_Hotel_Automatic is

    -- FSM Resepsionis
    type state_type is (
        idle,
        input_data,
        encrypt_password,
        authenticate,
        access_granted,
        access_denied
    );
    signal state : state_type := idle;

    -- Penyimpanan data tamu
    signal stored_username : integer range 0 to 9999 := 0;
    signal stored_password : integer range 0 to 9999 := 0;
    signal encrypted_pass  : integer := 0;

    -- KEY enkripsi sederhana
    constant ENC_KEY : integer := 7;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            state          <= idle;
            auth_enable    <= '0';
            valid_user     <= '0';
            encrypted_pass <= 0;

        elsif rising_edge(clk) then

            -- default
            auth_enable <= '0';
            valid_user  <= '0';

            case state is

                --------------------------------------------------
                -- IDLE : menunggu input dari aplikasi
                --------------------------------------------------
                when idle =>
                    if start_input = '1' then
                        state <= input_data;
                    end if;

                --------------------------------------------------
                -- INPUT DATA TAMU
                --------------------------------------------------
                when input_data =>
                    stored_username <= username_in;
                    stored_password <= password_in;
                    state           <= encrypt_password;

                --------------------------------------------------
                -- ENKRIPSI PASSWORD
                -- (representasi modul enkripsi)
                --------------------------------------------------
                when encrypt_password =>
                    encrypted_pass <= stored_password + ENC_KEY;
                    state          <= authenticate;

                --------------------------------------------------
                -- OTENTIKASI USERNAME & PASSWORD
                --------------------------------------------------
                when authenticate =>
                    if (username_in = stored_username) and
                       ((password_in + ENC_KEY) = encrypted_pass) then
                        state <= access_granted;
                    else
                        state <= access_denied;
                    end if;

                --------------------------------------------------
                -- AKSES KAMAR DIBERIKAN
                --------------------------------------------------
                when access_granted =>
                    auth_enable <= '1';
                    valid_user  <= '1';
                    state       <= idle;

                --------------------------------------------------
                -- AKSES DITOLAK
                --------------------------------------------------
                when access_denied =>
                    auth_enable <= '0';
                    valid_user  <= '0';
                    state       <= idle;

            end case;
        end if;
    end process;

    enc_password <= encrypted_pass;

end architecture Behavioral;
