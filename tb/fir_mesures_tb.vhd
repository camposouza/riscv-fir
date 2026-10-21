-- Performance testbench for the FIR programs (sw/fir_base.vhd and
-- sw/fir_macdm.vhd). Both programs share data, memory map and measurement
-- window, so this testbench works for either one: copy the chosen ROM into
-- instruction_memory.vhd before simulating.
--
-- Measurement window: from the last setup store (x[15] to Mem[184]) to the
-- store of the last output (y[22] to Mem[496]), both detected on the
-- data_memory write port. Reported: cycles, instructions, load-use stalls,
-- taken branches and CPI. Checked: the 23 outputs y[0-22].
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_debug_types.all;

entity fir_mesures_tb is
end entity;

architecture sim of fir_mesures_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant TIMEOUT    : natural := 5000;

    constant START_ADDRESS : natural := 184;
    constant END_ADDRESS   : natural := 496;

    constant Y_WORD : natural := 40;   -- y[0] at byte 320
    type y_array_t is array (0 to 22) of natural;
    constant Y_EXPECTED : y_array_t := (
        4, 19, 51, 100, 149, 191, 225, 245, 262, 285, 310, 330,
        345, 351, 347, 334, 307, 263, 199, 131, 73, 31, 8
    );

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    signal measuring            : std_logic := '0';
    signal done                 : std_logic := '0';
    signal cycle_count          : natural := 0;
    signal load_use_stall_count : natural := 0;
    signal taken_branch_count   : natural := 0;
begin
    dut : entity work.riscv_core(rtl)
        port map (
            clk   => clk,
            reset => reset
        );

    clk <= not clk after CLK_PERIOD / 2;

    monitor_performance : process(clk)
        alias pc_write_dbg is << signal .fir_mesures_tb.dut.pc_write : std_logic >>;
        alias if_id_write_dbg is << signal .fir_mesures_tb.dut.if_id_write : std_logic >>;
        alias id_ex_flush_dbg is << signal .fir_mesures_tb.dut.id_ex_flush : std_logic >>;
        alias branch_taken_dbg is << signal .fir_mesures_tb.dut.branch_taken : std_logic >>;
        alias mem_write_dbg is << signal .fir_mesures_tb.dut.u_datapath.u_data_memory.mem_write : std_logic >>;
        alias write_address_dbg is << signal .fir_mesures_tb.dut.u_datapath.u_data_memory.write_address : std_logic_vector(63 downto 0) >>;
    begin
        if rising_edge(clk) then
            if reset = '0' and done = '0' then
                if measuring = '1' then
                    cycle_count <= cycle_count + 1;

                    if pc_write_dbg = '0' and if_id_write_dbg = '0' and
                       id_ex_flush_dbg = '1' then
                        load_use_stall_count <= load_use_stall_count + 1;
                    end if;

                    if branch_taken_dbg = '1' then
                        taken_branch_count <= taken_branch_count + 1;
                    end if;

                    if mem_write_dbg = '1' and to_integer(unsigned(write_address_dbg(15 downto 0))) = END_ADDRESS then
                        done <= '1';
                    end if;
                elsif mem_write_dbg = '1' and to_integer(unsigned(write_address_dbg(15 downto 0))) = START_ADDRESS then
                    measuring <= '1';
                end if;
            end if;
        end if;
    end process;

    stimulus : process
        alias memory_dbg is << signal .fir_mesures_tb.dut.u_datapath.u_data_memory.memory : data_memory_array_t >>;

        variable instruction_count : natural;
    begin
        -- Reset is synchronous; release it after the first clock edge.
        wait until rising_edge(clk);
        wait for 1 ns;
        reset <= '0';

        wait until done = '1' for TIMEOUT * CLK_PERIOD;
        assert done = '1' report "y[22] was not written before the timeout" severity failure;
        wait until rising_edge(clk);

        for n in y_array_t'range loop
            assert memory_dbg(Y_WORD + n) = std_logic_vector(to_unsigned(Y_EXPECTED(n), 64))
                report "y[" & integer'image(n) & "]: expected " & integer'image(Y_EXPECTED(n)) &
                       ", got " & integer'image(to_integer(unsigned(memory_dbg(Y_WORD + n)(31 downto 0))))
                severity error;
        end loop;

        -- Each cycle in the window either completes an instruction, is a
        -- load-use bubble, or is one of the two flushed slots of a taken branch.
        instruction_count := cycle_count - load_use_stall_count - 2 * taken_branch_count;

        report "FIR performance:" & LF &
               "  cycles          = " & integer'image(cycle_count) & LF &
               "  instructions    = " & integer'image(instruction_count) & LF &
               "  load-use stalls = " & integer'image(load_use_stall_count) & LF &
               "  taken branches  = " & integer'image(taken_branch_count) & LF &
               "  CPI             = " & real'image(real(cycle_count) / real(instruction_count));

        assert false
            report "fir_mesures_tb completed successfully"
            severity note;
        std.env.stop;
        wait;
    end process;
end architecture;
