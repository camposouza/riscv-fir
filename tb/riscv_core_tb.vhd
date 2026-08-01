library ieee;
use ieee.std_logic_1164.all;
use work.riscv_debug_types.all;

entity riscv_core_tb is
end entity;

architecture sim of riscv_core_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal pc_src      : std_logic;
    signal mem_read    : std_logic;
    signal mem_to_reg  : std_logic;
    signal mem_write   : std_logic;
    signal alu_src     : std_logic;
    signal reg_write   : std_logic;
    signal alu_control : std_logic_vector(3 downto 0);
    signal instruction : std_logic_vector(31 downto 0);
    signal zero        : std_logic;

begin
    datapath : entity work.datapath(structural)
        port map (
            clk         => clk,
            reset       => reset,
            pc_src      => pc_src,
            mem_read    => mem_read,
            mem_to_reg  => mem_to_reg,
            mem_write   => mem_write,
            alu_src     => alu_src,
            reg_write   => reg_write,
            alu_control => alu_control,
            instruction => instruction,
            zero        => zero
        );

    controller : entity work.control_unit(rtl)
        port map (
            opcode      => instruction(6 downto 0),
            zero        => zero,
            funct3      => instruction(14 downto 12),
            funct7      => instruction(31 downto 25),
            pc_src      => pc_src,
            mem_read    => mem_read,
            mem_to_reg  => mem_to_reg,
            mem_write   => mem_write,
            alu_src     => alu_src,
            reg_write   => reg_write,
            alu_control => alu_control
        );

    clk <= not clk after CLK_PERIOD / 2;

    stimulus : process
    -- Local aliases to select array elements in simulation.
    alias registers_dbg is << signal .riscv_core_tb.datapath.u_register_file.registers : register_array_t >>;
    alias memory_dbg is << signal .riscv_core_tb.datapath.u_data_memory.memory : data_memory_array_t >>;

    alias x1 is registers_dbg(1);
    alias x2 is registers_dbg(2);
    alias x3 is registers_dbg(3);
    alias x4 is registers_dbg(4);
    alias x5 is registers_dbg(5);
    alias x6 is registers_dbg(6);
    alias memory_0 is memory_dbg(0);
    
    begin
        -- Reset is synchronous. The first rising edge places the PC at ROM[0].
        wait until rising_edge(clk);
        wait for 1 ns;
        assert instruction = x"00A00093"
            report "Expected 'addi x1, x0, 10' at ROM[0]"
            severity error;
        assert alu_src = '1' and reg_write = '1' and alu_control = "0010"
            report "Incorrect control signals for ADDI"
            severity error;

        reset <= '0';

        -- x1 = 10 and the next instruction is 'addi x2, x0, 20'.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert x1 = x"000000000000000A"
            report "ADDI did not write 10 to x1"
            severity error;
        assert instruction = x"01400113"
            report "Expected 'addi x2, x0, 20' at ROM[1]"
            severity error;

        -- x2 = 20 and the next instruction is 'add x3, x1, x2'.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert x2 = x"0000000000000014"
            report "ADDI did not write 20 to x2"
            severity error;
        assert instruction = x"002081B3"
            report "Expected 'add x3, x1, x2' at ROM[2]"
            severity error;

        -- x3 = 10 + 20 and the next instruction is the store.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert x3 = x"000000000000001E"
            report "ADD did not write 30 to x3"
            severity error;
        assert instruction = x"00302023"
            report "Expected 'sw x3, 0(x0)' at ROM[3]"
            severity error;
        assert mem_write = '1' and alu_src = '1' and reg_write = '0'
            report "Incorrect control signals for SW"
            severity error;

        -- The synchronous store completes on this edge; the next instruction
        -- is the load from the same memory location.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert memory_0 = x"000000000000001E"
            report "SW did not store 30 at memory address zero"
            severity error;
        assert instruction = x"00002203"
            report "Expected 'lw x4, 0(x0)' at ROM[4]"
            severity error;
        assert mem_read = '1' and mem_to_reg = '1' and reg_write = '1'
            report "Incorrect control signals for LW"
            severity error;

        -- The load writes x4 = 30. The following BEQ must see equal operands.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert x4 = x"000000000000001E"
            report "LW did not write 30 to x4"
            severity error;
        assert instruction = x"00418463"
            report "Expected 'beq x3, x4, OK' at ROM[5]"
            severity error;
        assert zero = '1' and pc_src = '1'
            report "BEQ should select the branch target when x3 equals x4"
            severity error;

        -- The branch offset is +8 bytes, so ROM[6] (addi x5, x0, 1) is skipped.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert instruction = x"02A00313"
            report "BEQ did not branch to the OK label"
            severity error;
        assert x5 = x"0000000000000000"
            report "x5 was modified even though the instruction must be skipped"
            severity error;

        -- The instruction at OK writes x6 = 42.
        wait until rising_edge(clk);
        wait for 1 ns;
        assert x6 = x"000000000000002A"
            report "ADDI at OK did not write 42 to x6"
            severity error;

        assert false
            report "riscv_core_tb completed successfully"
            severity note;
        wait;
    end process;
end architecture;
