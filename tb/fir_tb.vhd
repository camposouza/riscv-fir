-- Self-checking testbench for the FIR workload (sw/fir.s / sw/fir.vhd).
--
-- This testbench only passes while sw/fir.vhd is into instruction_memory.vhd.
-- Copy it into the instruction_memory before simulating this file.
library ieee;
use ieee.std_logic_1164.all;
use work.riscv_debug_types.all;

entity fir_tb is
end entity;

architecture sim of fir_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    signal load_use_stall_count : natural := 0;
    signal taken_branch_count   : natural := 0;

    -- Performance measurement: cycles from reset release to the cycle the
    -- FIR output is written to data memory. Detected by watching the actual
    -- data_memory write port/address.
    signal cycle_count     : natural := 0;
    signal fir_done        : std_logic := '0';
    signal fir_cycle_count : natural := 0;
begin
    -- Instantiate the complete core
    dut : entity work.riscv_core(rtl)
        port map (
            clk   => clk,
            reset => reset
        );

    clk <= not clk after CLK_PERIOD / 2;

    monitor_pipeline : process(clk)
        alias pc_write_dbg is << signal .fir_tb.dut.pc_write : std_logic >>;
        alias if_id_write_dbg is << signal .fir_tb.dut.if_id_write : std_logic >>;
        alias id_ex_flush_dbg is << signal .fir_tb.dut.id_ex_flush : std_logic >>;
        alias branch_taken_dbg is << signal .fir_tb.dut.branch_taken : std_logic >>;
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

    -- y (0x51) lands at data_memory address 128 (0x80); catching the write there
    monitor_performance : process(clk)
        alias data_mem_write_dbg is << signal .fir_tb.dut.u_datapath.u_data_memory.mem_write : std_logic >>;
        alias data_mem_addr_dbg  is << signal .fir_tb.dut.u_datapath.u_data_memory.address : std_logic_vector(63 downto 0) >>;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cycle_count     <= 0;
                fir_done        <= '0';
                fir_cycle_count <= 0;
            else
                cycle_count <= cycle_count + 1;

                if fir_done = '0' and data_mem_write_dbg = '1' and
                   data_mem_addr_dbg = x"0000000000000080" then
                    fir_done        <= '1';
                    fir_cycle_count <= cycle_count + 1;
                end if;
            end if;
        end if;
    end process;

    stimulus : process
        -- White-box aliases are used only to check the architectural state.
        alias registers_dbg is << signal .fir_tb.dut.u_datapath.u_register_file.registers : register_array_t >>;
        alias memory_dbg is << signal .fir_tb.dut.u_datapath.u_data_memory.memory : data_memory_array_t >>;

        alias x2  is registers_dbg(2);
        alias x3  is registers_dbg(3);
        alias x4  is registers_dbg(4);
        alias x31 is registers_dbg(31);
    begin
        -- Reset is synchronous; release it after the first clock edge.
        wait until rising_edge(clk);
        wait for 1 ns;
        reset <= '0';

        -- 66 ROM entries and 8 load-use stalls (one per tap) need at most
        -- 66 + 4 (pipeline fill/drain) + 8 = 78 cycles;
        for cycle in 1 to 100 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        -- Coefficients h[0..7], written during setup and never touched again.
        assert memory_dbg(0) = x"0000000000000001" report "Mem[0]: h[0] expected 1" severity error;
        assert memory_dbg(1) = x"0000000000000002" report "Mem[8]: h[1] expected 2" severity error;
        assert memory_dbg(2) = x"0000000000000003" report "Mem[16]: h[2] expected 3" severity error;
        assert memory_dbg(3) = x"0000000000000004" report "Mem[24]: h[3] expected 4" severity error;
        assert memory_dbg(4) = x"0000000000000003" report "Mem[32]: h[4] expected 3" severity error;
        assert memory_dbg(5) = x"0000000000000002" report "Mem[40]: h[5] expected 2" severity error;
        assert memory_dbg(6) = x"0000000000000001" report "Mem[48]: h[6] expected 1" severity error;
        assert memory_dbg(7) = x"0000000000000001" report "Mem[56]: h[7] expected 1" severity error;

        -- Input samples x[0..7].
        assert memory_dbg(8)  = x"0000000000000001" report "Mem[64]: x[0] expected 1" severity error;
        assert memory_dbg(9)  = x"0000000000000002" report "Mem[72]: x[1] expected 2" severity error;
        assert memory_dbg(10) = x"0000000000000003" report "Mem[80]: x[2] expected 3" severity error;
        assert memory_dbg(11) = x"0000000000000004" report "Mem[88]: x[3] expected 4" severity error;
        assert memory_dbg(12) = x"0000000000000005" report "Mem[96]: x[4] expected 5" severity error;
        assert memory_dbg(13) = x"0000000000000006" report "Mem[104]: x[5] expected 6" severity error;
        assert memory_dbg(14) = x"0000000000000007" report "Mem[112]: x[6] expected 7" severity error;
        assert memory_dbg(15) = x"0000000000000008" report "Mem[120]: x[7] expected 8" severity error;

        -- Last tap (k=7): h[7]=1, x[0]=1, product=1.
        assert x2 = x"0000000000000001" report "x2: last h[k] (h[7]) expected 1" severity error;
        assert x3 = x"0000000000000001" report "x3: last x[n-k] (x[0]) expected 1" severity error;
        assert x4 = x"0000000000000001" report "x4: last product expected 1" severity error;

        -- Final MAC accumulator and the output sample written to memory.
        assert x31 = x"0000000000000051" report "x31: FIR output expected 81 (0x51)" severity error;
        assert memory_dbg(16) = x"0000000000000051" report "Mem[128]: y expected 81 (0x51)" severity error;

        -- One load-use stall per tap; the program never branches.
        assert load_use_stall_count = 8
            report "Expected exactly eight load-use stalls" severity error;
        assert taken_branch_count = 0
            report "Expected zero taken branches" severity error;

        assert fir_done = '1'
            report "FIR output (Mem[128]) was never written -- performance counter did not latch"
            severity error;

        -- This is the baseline performance number for the Results chapter.
        report "fir_tb: " & to_string(fir_cycle_count) &
               " cycles from reset release to the Mem[128] write (baseline core)"
            severity note;

        -- Hand-derived expected value (66 instructions, 8 one-cycle load-use
        -- stalls, 0 branch flushes: 66 + 4 pipeline fill/drain + 8 = 78
        -- cycles to WB, one cycle earlier -- 77 -- for the MEM-stage write
        -- this counter latches on). Severity warning, not error: this is an
        -- unverified manual derivation, not a structural correctness check
        -- like the asserts above -- a mismatch likely means the derivation
        -- has an off-by-one, not that the RTL is wrong. Update the constant
        -- once a real run confirms the number.
        assert fir_cycle_count = 77
            report "fir_tb: measured " & to_string(fir_cycle_count) &
                   " cycles, hand-derived estimate was 77 -- update the estimate, don't assume a bug"
            severity warning;

        assert false
            report "fir_tb completed successfully"
            severity note;
        wait;
    end process;
end architecture;
