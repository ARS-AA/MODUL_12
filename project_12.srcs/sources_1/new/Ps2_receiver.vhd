----------------------------------------------------------------------------------
-- Jobsheet 12 - ps2_receiver.vhd (Prosedur 1, Kode 12.1 + perbaikan)
-- Penerima scan code PS/2 (dari PIC24 via port USB-HID Basys 3)
-- Port identik dengan Kode 12.1. Perbaikan:
--   * start/stop/parity ganjil diperiksa, data_ready hanya jika frame valid
--   * timeout 200 us: bit_cnt di-reset bila frame terputus (resync)
--   * scan_code diberi nilai awal; falling_edge diganti ps2_fall
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ps2_receiver is
    Port ( clk        : in  STD_LOGIC;                      -- clock sistem 100 MHz
           ps2_clk    : in  STD_LOGIC;
           ps2_data   : in  STD_LOGIC;
           scan_code  : out STD_LOGIC_VECTOR (7 downto 0);
           data_ready : out STD_LOGIC );                    -- pulsa 1 siklus
end ps2_receiver;

architecture Behavioral of ps2_receiver is
    signal clk_ff1, clk_ff2, clk_ff3 : STD_LOGIC := '1';
    signal data_ff1, data_ff2        : STD_LOGIC := '1';
    signal ps2_fall                  : STD_LOGIC;

    signal shift_reg   : STD_LOGIC_VECTOR (10 downto 0) := (others => '1');
    signal bit_cnt     : integer range 0 to 10 := 0;

    constant TIMEOUT_MAX : integer := 20000;               -- 200 us @ 100 MHz
    signal timeout_cnt : integer range 0 to TIMEOUT_MAX := 0;

    signal scan_code_i : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    function xor_all(v : STD_LOGIC_VECTOR) return STD_LOGIC is
        variable r : STD_LOGIC := '0';
    begin
        for i in v'range loop
            r := r xor v(i);
        end loop;
        return r;
    end function;
begin
    scan_code <= scan_code_i;

    -- Sinkronisasi sinyal asinkron
    process(clk)
    begin
        if rising_edge(clk) then
            clk_ff1  <= ps2_clk;  clk_ff2  <= clk_ff1; clk_ff3 <= clk_ff2;
            data_ff1 <= ps2_data; data_ff2 <= data_ff1;
        end if;
    end process;

    ps2_fall <= clk_ff3 and not clk_ff2;

    -- Penerima frame 11 bit
    process(clk)
    begin
        if rising_edge(clk) then
            data_ready <= '0';
            if ps2_fall = '1' then
                timeout_cnt        <= 0;
                shift_reg(bit_cnt) <= data_ff2;
                if bit_cnt = 10 then
                    bit_cnt <= 0;
                    -- shift_reg(0)=start, (8:1)=data, (9)=parity, data_ff2=stop (bit ke-10)
                    if shift_reg(0) = '0' and data_ff2 = '1'
                       and xor_all(shift_reg(9 downto 1)) = '1' then   -- parity ganjil
                        scan_code_i <= shift_reg(8 downto 1);
                        data_ready  <= '1';
                    end if;
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            elsif bit_cnt /= 0 then
                if timeout_cnt = TIMEOUT_MAX then
                    bit_cnt     <= 0;
                    timeout_cnt <= 0;
                else
                    timeout_cnt <= timeout_cnt + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;