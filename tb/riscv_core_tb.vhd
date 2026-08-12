library ieee;
use ieee.std_logic_1164.all;
use work.riscv_debug_types.all;

entity riscv_core_tb is
end entity;

architecture sim of riscv_core_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    signal load_use_stall_count : natural := 0;
    signal taken_branch_count   : natural := 0;
begin
    -- Instantiate the complete core so that the test includes the hazard
    -- detection and forwarding units, rather than testing the datapath alone.
    dut : entity work.riscv_core(rtl)
        port map (
            clk   => clk,
            reset => reset
        );

    clk <= not clk after CLK_PERIOD / 2;

    monitor_pipeline : process(clk)
        alias pc_write_dbg is << signal .riscv_core_tb.dut.pc_write : std_logic >>;
        alias if_id_write_dbg is << signal .riscv_core_tb.dut.if_id_write : std_logic >>;
        alias id_ex_flush_dbg is << signal .riscv_core_tb.dut.id_ex_flush : std_logic >>;
        alias branch_taken_dbg is << signal .riscv_core_tb.dut.branch_taken : std_logic >>;
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
        alias registers_dbg is << signal .riscv_core_tb.dut.u_datapath.u_register_file.registers : register_array_t >>;
        alias memory_dbg is << signal .riscv_core_tb.dut.u_datapath.u_data_memory.memory : data_memory_array_t >>;

        alias x1  is registers_dbg(1);
        alias x2  is registers_dbg(2);
        alias x3  is registers_dbg(3);
        alias x4  is registers_dbg(4);
        alias x5  is registers_dbg(5);
        alias x6  is registers_dbg(6);
        alias x7  is registers_dbg(7);
        alias x8  is registers_dbg(8);
        alias x9  is registers_dbg(9);
        alias x10 is registers_dbg(10);
        alias x11 is registers_dbg(11);
        alias x12 is registers_dbg(12);
        alias x13 is registers_dbg(13);
        alias x14 is registers_dbg(14);
        alias x15 is registers_dbg(15);
        alias x16 is registers_dbg(16);
        alias x17 is registers_dbg(17);
        alias x18 is registers_dbg(18);
        alias x19 is registers_dbg(19);
        alias x31 is registers_dbg(31);
    begin
        -- Reset is synchronous; release it after the first clock edge.
        wait until rising_edge(clk);
        wait for 1 ns;
        reset <= '0';

        -- 26 ROM entries, two load-use stalls and three branch flushes fit
        -- comfortably in this interval. The trailing NOPs cannot alter state.
        for cycle in 1 to 45 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        -- ALU operations and forwarding chain.
        assert x1 = x"000000000000000A" report "x1: expected 10" severity error;
        assert x2 = x"0000000000000003" report "x2: expected 3" severity error;
        assert x3 = x"000000000000000D" report "ADD/forwarding: x3 expected 13" severity error;
        assert x4 = x"000000000000000A" report "SUB/forwarding: x4 expected 10" severity error;
        assert x5 = x"000000000000000A" report "AND/forwarding: x5 expected 10" severity error;
        assert x6 = x"000000000000000B" report "OR/forwarding: x6 expected 11" severity error;

        -- First store/load pair and its immediate load-use dependency.
        assert memory_dbg(0) = x"000000000000000B" report "Mem[0]: expected 11" severity error;
        assert x7 = x"000000000000000B" report "LW: x7 expected 11" severity error;
        assert x8 = x"000000000000000C" report "Load-use result: x8 expected 12" severity error;
        assert x9 = x"0000000000000017" report "ADD after load: x9 expected 23" severity error;

        -- Taken and not-taken branch behavior.
        assert x10 = x"0000000000000000" report "Taken branch failed to flush x10 instruction" severity error;
        assert x11 = x"0000000000000000" report "Taken branch failed to flush x11 instruction" severity error;
        assert x12 = x"0000000000000007" report "Not-taken branch incorrectly skipped x12" severity error;

        -- Second store/load pair and load-dependent branch.
        assert x13 = x"0000000000000010" report "x13: expected 16" severity error;
        assert memory_dbg(1) = x"0000000000000010" report "Mem[8]: expected 16" severity error;
        assert x14 = x"0000000000000010" report "LW: x14 expected 16" severity error;
        assert x15 = x"000000000000001A" report "x15: expected 26" severity error;
        assert x16 = x"0000000000000000" report "Taken branch failed to flush x16 instruction" severity error;
        assert x17 = x"0000000000000000" report "Taken branch failed to flush x17 instruction" severity error;
        assert x18 = x"0000000000000000" report "Taken branch failed to flush x18 instruction" severity error;
        assert x19 = x"0000000000000000" report "Taken branch failed to flush x19 instruction" severity error;

        -- The program's success marker is written only after the final branch.
        assert x31 = x"0000000000000055" report "Program did not reach PASS" severity error;

        -- There are two immediate dependencies on LW and three taken BEQs.
        assert load_use_stall_count = 2
            report "Expected exactly two load-use stalls" severity error;
        assert taken_branch_count = 3
            report "Expected exactly three taken branches" severity error;

        assert false
            report "riscv_core_tb completed successfully"
            severity note;
        wait;
    end process;
end architecture;
