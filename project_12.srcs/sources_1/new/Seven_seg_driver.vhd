----------------------------------------------------------------------------------
-- Jobsheet 12 - seven_seg_driver.vhd
-- Driver seven-segment 4 digit Basys 3 (common anode, aktif rendah), multiplexing
-- seg(0)=CA ... seg(6)=CG ; value(15:12) digit paling kiri
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_driver is
    Port ( clk   : in  STD_LOGIC;                         -- 100 MHz
           value : in  STD_LOGIC_VECTOR (15 downto 0);    -- 4 digit heksadesimal
           seg   : out STD_LOGIC_VECTOR (6 downto 0);
           an    : out STD_LOGIC_VECTOR (3 downto 0) );
end seven_seg_driver;

architecture Behavioral of seven_seg_driver is
    signal refresh_cnt : unsigned (19 downto 0) := (others => '0');
    signal sel         : STD_LOGIC_VECTOR (1 downto 0);
    signal nibble      : STD_LOGIC_VECTOR (3 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;

    sel <= STD_LOGIC_VECTOR(refresh_cnt(18 downto 17));   -- ~1,3 ms per digit

    process(sel, value)
    begin
        case sel is
            when "00"   => an <= "1110"; nibble <= value(3 downto 0);
            when "01"   => an <= "1101"; nibble <= value(7 downto 4);
            when "10"   => an <= "1011"; nibble <= value(11 downto 8);
            when others => an <= "0111"; nibble <= value(15 downto 12);
        end case;
    end process;

    -- urutan bit: g f e d c b a (aktif rendah)
    with nibble select
        seg <= "1000000" when x"0",
               "1111001" when x"1",
               "0100100" when x"2",
               "0110000" when x"3",
               "0011001" when x"4",
               "0010010" when x"5",
               "0000010" when x"6",
               "1111000" when x"7",
               "0000000" when x"8",
               "0010000" when x"9",
               "0001000" when x"A",
               "0000011" when x"B",
               "1000110" when x"C",
               "0100001" when x"D",
               "0000110" when x"E",
               "0001110" when others;
end Behavioral;