----------------------------------------------------------------------------------
-- Jobsheet 12 - ps2_key_decoder.vhd (Tugas Praktikum 2)
-- FSM pembeda make code / break code (0xF0 + kode), juga mengenali prefix 0xE0
-- Keluaran key_valid berupa pulsa 1 siklus per kejadian tombol.
--   is_break = '0' : tombol ditekan (make)   is_break = '1' : tombol dilepas
--   is_ext   = '1' : tombol extended (didahului 0xE0)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ps2_key_decoder is
    Port ( clk        : in  STD_LOGIC;
           scan_code  : in  STD_LOGIC_VECTOR (7 downto 0);
           data_ready : in  STD_LOGIC;
           key_code   : out STD_LOGIC_VECTOR (7 downto 0);
           key_valid  : out STD_LOGIC;
           is_break   : out STD_LOGIC;
           is_ext     : out STD_LOGIC );
end ps2_key_decoder;

architecture Behavioral of ps2_key_decoder is
    type kb_state is (IDLE, GOT_E0, GOT_F0);
    signal st    : kb_state := IDLE;
    signal ext_r : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            key_valid <= '0';
            if data_ready = '1' then
                case st is
                    when IDLE =>
                        if scan_code = x"F0" then
                            ext_r <= '0';
                            st    <= GOT_F0;
                        elsif scan_code = x"E0" then
                            ext_r <= '1';
                            st    <= GOT_E0;
                        else
                            key_code  <= scan_code;
                            is_break  <= '0';
                            is_ext    <= '0';
                            key_valid <= '1';
                        end if;

                    when GOT_E0 =>
                        if scan_code = x"F0" then
                            st <= GOT_F0;              -- E0 F0 xx = break extended
                        else
                            key_code  <= scan_code;    -- E0 xx = make extended
                            is_break  <= '0';
                            is_ext    <= '1';
                            key_valid <= '1';
                            st        <= IDLE;
                        end if;

                    when GOT_F0 =>
                        key_code  <= scan_code;        -- kode setelah F0 = tombol dilepas
                        is_break  <= '1';
                        is_ext    <= ext_r;
                        key_valid <= '1';
                        ext_r     <= '0';
                        st        <= IDLE;
                end case;
            end if;
        end if;
    end process;
end Behavioral;