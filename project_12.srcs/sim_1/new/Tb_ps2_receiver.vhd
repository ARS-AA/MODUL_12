----------------------------------------------------------------------------------
-- Jobsheet 12 - tb_ps2_receiver.vhd (Prosedur 2)
-- Mensimulasikan frame PS/2 lengkap, periode clock PS/2 = 60 us (~16,7 kHz)
-- Kasus uji: make code, break code, parity salah, frame terputus (timeout)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_ps2_receiver is
end tb_ps2_receiver;

architecture sim of tb_ps2_receiver is
    signal clk        : STD_LOGIC := '0';
    signal ps2_clk    : STD_LOGIC := '1';
    signal ps2_data   : STD_LOGIC := '1';
    signal scan_code  : STD_LOGIC_VECTOR (7 downto 0);
    signal data_ready : STD_LOGIC;

    signal sim_done    : boolean := false;
    signal ready_count : integer := 0;
    signal last_code   : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    -- Kirim satu frame PS/2: start, 8 data (LSB dulu), parity ganjil, stop
    procedure ps2_send_frame(
        signal   s_clk      : out STD_LOGIC;
        signal   s_data     : out STD_LOGIC;
        constant data       : in  STD_LOGIC_VECTOR (7 downto 0);
        constant bad_parity : in  boolean := false;
        constant nbits      : in  integer := 11) is
        variable frame : STD_LOGIC_VECTOR (10 downto 0);
        variable p     : STD_LOGIC := '1';
    begin
        for i in 0 to 7 loop
            p := p xor data(i);                 -- p = not(xor data) -> parity ganjil
        end loop;
        if bad_parity then
            p := not p;
        end if;
        frame(0)          := '0';
        frame(8 downto 1) := data;
        frame(9)          := p;
        frame(10)         := '1';
        for i in 0 to nbits - 1 loop
            s_data <= frame(i);
            wait for 15 us;
            s_clk  <= '0';
            wait for 30 us;
            s_clk  <= '1';
            wait for 15 us;                      -- total 60 us per bit
        end loop;
        s_data <= '1';
    end procedure;
begin
    uut : entity work.ps2_receiver
        port map ( clk => clk, ps2_clk => ps2_clk, ps2_data => ps2_data,
                   scan_code => scan_code, data_ready => data_ready );

    -- clock 100 MHz
    clk_gen : process
    begin
        while not sim_done loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    -- monitor data_ready
    monitor : process(clk)
    begin
        if rising_edge(clk) then
            if data_ready = '1' then
                last_code   <= scan_code;
                ready_count <= ready_count + 1;
            end if;
        end if;
    end process;

    stim : process
    begin
        wait for 10 us;

        -- Uji 1: make code 'A' (0x1C)
        ps2_send_frame(ps2_clk, ps2_data, x"1C");
        wait for 20 us;
        assert ready_count = 1 and last_code = x"1C"
            report "Uji 1 GAGAL: make code 0x1C" severity error;

        -- Uji 2: break code (0xF0 lalu 0x1C)
        ps2_send_frame(ps2_clk, ps2_data, x"F0");
        wait for 20 us;
        assert ready_count = 2 and last_code = x"F0"
            report "Uji 2a GAGAL: 0xF0" severity error;
        ps2_send_frame(ps2_clk, ps2_data, x"1C");
        wait for 20 us;
        assert ready_count = 3 and last_code = x"1C"
            report "Uji 2b GAGAL: 0x1C setelah F0" severity error;

        -- Uji 3: parity salah harus ditolak (data_ready tidak muncul)
        ps2_send_frame(ps2_clk, ps2_data, x"32", bad_parity => true);
        wait for 20 us;
        assert ready_count = 3
            report "Uji 3 GAGAL: frame parity salah diterima" severity error;

        -- Uji 4: frame terputus (5 bit) lalu timeout, frame berikutnya harus normal
        ps2_send_frame(ps2_clk, ps2_data, x"55", nbits => 5);
        wait for 300 us;
        ps2_send_frame(ps2_clk, ps2_data, x"21");
        wait for 20 us;
        assert ready_count = 4 and last_code = x"21"
            report "Uji 4 GAGAL: resync setelah timeout" severity error;

        -- Uji 5: frame valid biasa (0x32)
        ps2_send_frame(ps2_clk, ps2_data, x"32");
        wait for 20 us;
        assert ready_count = 5 and last_code = x"32"
            report "Uji 5 GAGAL: make code 0x32" severity error;

        report "Simulasi selesai. Jika tidak ada pesan GAGAL, semua uji LULUS." severity note;
        sim_done <= true;
        wait;
    end process;
end sim;