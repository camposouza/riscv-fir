-- Self-checking testbench for the macdm verification program
-- (sw/macdm_verif.s / sw/macdm_verif.vhd).
--
-- This testbench only passes while sw/macdm_verif.vhd is in
-- instruction_memory.vhd. Copy it into the instruction_memory before
-- simulating this file.
library ieee;
use ieee.std_logic_1164.all;
use work.riscv_debug_types.all;

entity macdm_verif_tb is
end entity;

architecture sim of macdm_verif_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    signal load_use_stall_count : natural := 0;
    signal taken_branch_count   : natural := 0;
begin
    dut : entity work.riscv_core(rtl)
        port map (
            clk   => clk,
            reset => reset
        );

    clk <= not clk after CLK_PERIOD / 2;

    monitor_pipeline : process(clk)
        alias pc_write_dbg is << signal .macdm_verif_tb.dut.pc_write : std_logic >>;
        alias if_id_write_dbg is << signal .macdm_verif_tb.dut.if_id_write : std_logic >>;
        alias id_ex_flush_dbg is << signal .macdm_verif_tb.dut.id_ex_flush : std_logic >>;
        alias branch_taken_dbg is << signal .macdm_verif_tb.dut.branch_taken : std_logic >>;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                load_use_stall_count <= 0;
                taken_branch_count   <= 0;
            else
                -- The HDU characterizes a load-use stall by freezing both
                -- IF and ID and inserting a bubble into EX.
                if pc_write_dbg = '0' and if_id_write_dbg = '0' and
                   id_ex_flush_dbg = '1' then
                    load_use_stall_count <= load_use_stall_count + 1;
                end if;

                if branch_taken_dbg = '1' then
                    taken_branch_count <= taken_branch_count + 1;
                end if;
            end if;
        end if;
    end process;

    stimulus : process
        -- White-box aliases are used only to check the architectural state.
        alias registers_dbg is << signal .macdm_verif_tb.dut.u_datapath.u_register_file.registers : register_array_t >>;
        alias memory_dbg is << signal .macdm_verif_tb.dut.u_datapath.u_data_memory.memory : data_memory_array_t >>;

        alias x1  is registers_dbg(1);
        alias x20 is registers_dbg(20);
        alias x21 is registers_dbg(21);
        alias x22 is registers_dbg(22);
        alias x23 is registers_dbg(23);
        alias x24 is registers_dbg(24);
        alias x25 is registers_dbg(25);
        alias x26 is registers_dbg(26);
        alias x27 is registers_dbg(27);
        alias x28 is registers_dbg(28);
        alias x30 is registers_dbg(30);
        alias x31 is registers_dbg(31);
    begin
        -- Reset is synchronous; release it after the first clock edge.
        wait until rising_edge(clk);
        wait for 1 ns;
        reset <= '0';

        -- 44 ROM entries, three load-use stalls and one branch flush fit
        -- comfortably in this interval. The trailing NOPs cannot alter state.
        for cycle in 1 to 80 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        -- 1. Accumulator from an ALU instruction and from the previous macdm
        -- (forward_m); the 2nd macdm reads the word moved by the 1st.
        assert memory_dbg(0) = x"000000000000000B" report "Mem[0]: expected 11 (macdm source unchanged)" severity error;
        assert memory_dbg(1) = x"000000000000000B" report "Mem[1]: expected 11 (moved from Mem[0])" severity error;
        assert memory_dbg(2) = x"000000000000000B" report "Mem[2]: expected 11 (moved from Mem[1])" severity error;
        assert x20 = x"0000000000000002" report "x20: expected 2" severity error;

        -- 2. Coefficient from lw (stall), accumulator via write-first bypass.
        assert x22 = x"0000000000000004" report "LW: x22 expected 4" severity error;
        assert memory_dbg(4) = x"0000000000000004" report "Mem[4]: expected 4" severity error;
        assert memory_dbg(5) = x"0000000000000006" report "Mem[5]: expected 6" severity error;
        assert memory_dbg(6) = x"0000000000000006" report "Mem[6]: expected 6 (moved from Mem[5])" severity error;

        -- 3. Accumulator at distance 2 (forward_c). The chain also covers
        -- blocks 1 and 2 and the two flushed macdm that must not change it.
        assert x23 = x"0000000000000003" report "x23: expected 3" severity error;
        assert x21 = x"0000000000000067" report "macdm accumulator chain: x21 expected 103" severity error;

        -- 4. lw right after macdm sees the moved word; accumulator from
        -- that lw (forward_m, no stall).
        assert x24 = x"0000000000000028" report "macdm with lw accumulator: x24 expected 40" severity error;
        assert memory_dbg(8)  = x"000000000000000A" report "Mem[8]: expected 10" severity error;
        assert memory_dbg(9)  = x"000000000000000A" report "Mem[9]: expected 10 (moved from Mem[8])" severity error;
        assert memory_dbg(10) = x"000000000000000A" report "Mem[10]: expected 10 (moved from Mem[9])" severity error;

        -- 5. Ordinary consumer of a macdm result (stall, then MEM/WB forwarding).
        assert x25 = x"000000000000008F" report "ADD after macdm: x25 expected 143" severity error;

        -- 6. Base forwarded from EX/MEM with a nonzero offset; the sw that
        -- follows overwrites the moved word (stall, then MEM/WB forwarding).
        assert x26 = x"0000000000000060" report "x26: expected 96" severity error;
        assert x27 = x"000000000000000E" report "macdm with forwarded base: x27 expected 14" severity error;
        assert memory_dbg(14) = x"0000000000000007" report "Mem[14]: expected 7" severity error;
        assert memory_dbg(15) = x"000000000000000E" report "Mem[15]: expected 14 (sw after the move)" severity error;

        -- 7. macdm right after sw to the word it reads.
        assert x1  = x"000000000000000D" report "x1: expected 13" severity error;
        assert x28 = x"00000000000000A9" report "macdm after sw: x28 expected 169" severity error;
        assert memory_dbg(16) = x"000000000000000D" report "Mem[16]: expected 13" severity error;
        assert memory_dbg(17) = x"000000000000000D" report "Mem[17]: expected 13 (moved from Mem[16])" severity error;

        -- 8. Delay line shifted one position right.
        assert x30 = x"0000000000000010" report "delay line: x30 expected 16" severity error;
        assert memory_dbg(20) = x"0000000000000001" report "Mem[20]: expected 1" severity error;
        assert memory_dbg(21) = x"0000000000000001" report "Mem[21]: expected 1 (shifted)" severity error;
        assert memory_dbg(22) = x"0000000000000002" report "Mem[22]: expected 2 (shifted)" severity error;
        assert memory_dbg(23) = x"0000000000000003" report "Mem[23]: expected 3 (shifted)" severity error;

        -- 9. A flushed macdm must not move data.
        assert memory_dbg(24) = x"0000000000000032" report "Mem[24]: expected 50" severity error;
        assert memory_dbg(25) = x"0000000000000000" report "Mem[25]: expected 0 (flushed macdm wrote memory)" severity error;

        assert x31 = x"0000000000000055" report "Program did not reach DONE" severity error;

        assert load_use_stall_count = 3
            report "Expected exactly three load-use stalls" severity error;
        assert taken_branch_count = 1
            report "Expected exactly one taken branch" severity error;

        assert false
            report "macdm_verif_tb completed successfully"
            severity note;
        std.env.stop;
        wait;
    end process;
end architecture;
