----------------------------------------------------------------------------------
-- Jobsheet 12 - js12_top.vhd (Prosedur 3, Tugas 1 dan 2)
--   sw(0) = '0' : seven-segment = 00 & scan code mentah terakhir (hex)  [Prosedur 3]
--   sw(0) = '1' : seven-segment = kode tombol & ASCII (hex)             [Tugas 1]
--   led(0)      : menyala selama tombol TARGET_KEY ditekan              [Tugas 2]
--   led(15:8)   : scan code mentah terakhir (biner)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity js12_top is
    Port ( clk     : in  STD_LOGIC;
           sw      : in  STD_LOGIC_VECTOR (0 downto 0);
           led     : out STD_LOGIC_VECTOR (15 downto 0);
           seg     : out STD_LOGIC_VECTOR (6 downto 0);
           dp      : out STD_LOGIC;
           an      : out STD_LOGIC_VECTOR (3 downto 0);
           PS2Clk  : in  STD_LOGIC;
           PS2Data : in  STD_LOGIC );
end js12_top;

architecture Structural of js12_top is
    constant TARGET_KEY : STD_LOGIC_VECTOR (7 downto 0) := x"1C";   -- tombol 'A'

    signal scan_code    : STD_LOGIC_VECTOR (7 downto 0);
    signal data_ready   : STD_LOGIC;

    signal key_code     : STD_LOGIC_VECTOR (7 downto 0);
    signal key_valid    : STD_LOGIC;
    signal key_is_break : STD_LOGIC;
    signal key_ext      : STD_LOGIC;

    signal last_raw     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal last_make    : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal ascii        : STD_LOGIC_VECTOR (7 downto 0);
    signal ascii_valid  : STD_LOGIC;

    signal disp_value   : STD_LOGIC_VECTOR (15 downto 0);
    signal led0_r       : STD_LOGIC := '0';
begin
    u_rx : entity work.ps2_receiver
        port map ( clk => clk, ps2_clk => PS2Clk, ps2_data => PS2Data,
                   scan_code => scan_code, data_ready => data_ready );

    u_dec : entity work.ps2_key_decoder
        port map ( clk => clk, scan_code => scan_code, data_ready => data_ready,
                   key_code => key_code, key_valid => key_valid,
                   is_break => key_is_break, is_ext => key_ext );

    u_ascii : entity work.scancode_to_ascii
        port map ( scan_code => last_make, ascii => ascii, valid => ascii_valid );

    u_disp : entity work.seven_seg_driver
        port map ( clk => clk, value => disp_value, seg => seg, an => an );

    -- simpan scan code mentah terakhir dan make code terakhir
    process(clk)
    begin
        if rising_edge(clk) then
            if data_ready = '1' then
                last_raw <= scan_code;
            end if;
            if key_valid = '1' and key_is_break = '0' and key_ext = '0' then
                last_make <= key_code;
            end if;
            -- Tugas 2: led(0) ON saat TARGET_KEY ditekan, OFF saat dilepas
            if key_valid = '1' and key_ext = '0' and key_code = TARGET_KEY then
                led0_r <= not key_is_break;
            end if;
        end if;
    end process;

    disp_value <= x"00" & last_raw when sw(0) = '0' else last_make & ascii;

    led(0)           <= led0_r;
    led(7 downto 1)  <= (others => '0');
    led(15 downto 8) <= last_raw;
    dp               <= '1';                -- titik desimal mati
end Structural;