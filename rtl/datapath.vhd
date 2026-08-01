library ieee;
use ieee.std_logic_1164.all;

entity datapath is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;

        -- Signals from the control unit
        pc_src      : in  std_logic;
        mem_read    : in  std_logic;
        mem_to_reg  : in  std_logic;
        mem_write   : in  std_logic;
        alu_src     : in  std_logic;
        reg_write   : in  std_logic;
        alu_control : in std_logic_vector(3 downto 0);

        -- Signals sent to the control unit
        instruction : out std_logic_vector(31 downto 0);
        zero        : out std_logic
    );
end entity;

architecture structural of datapath is
    signal current_pc      : std_logic_vector(63 downto 0);
    signal pc_plus_4       : std_logic_vector(63 downto 0);
    signal branch_target   : std_logic_vector(63 downto 0);
    signal next_pc         : std_logic_vector(63 downto 0);

    signal instruction_i   : std_logic_vector(31 downto 0);
    signal immediate       : std_logic_vector(63 downto 0);
    signal read_data_1     : std_logic_vector(63 downto 0);
    signal read_data_2     : std_logic_vector(63 downto 0);
    signal alu_operand_b   : std_logic_vector(63 downto 0);
    signal alu_result      : std_logic_vector(63 downto 0);
    signal memory_data     : std_logic_vector(63 downto 0);
    signal write_back_data : std_logic_vector(63 downto 0);
begin
    -- Instruction fetch and PC update
    u_pc : entity work.pc(rtl)
        port map (
            clk     => clk,
            reset   => reset,
            next_pc => next_pc,
            pc_out  => current_pc
        );

    u_instruction_memory : entity work.instruction_memory(rtl)
        port map (
            address     => current_pc,
            instruction => instruction_i
        );

    u_pc_adder : entity work.adder(rtl)
        port map (
            a      => current_pc,
            b      => x"0000000000000004",
            result => pc_plus_4
        );

    -- The generator already includes the least significant zero bit for B-type.
    u_branch_adder : entity work.adder(rtl)
        port map (
            a      => current_pc,
            b      => immediate,
            result => branch_target
        );

    u_next_pc_mux : entity work.mux2(rtl)
        port map (
            input0 => pc_plus_4,
            input1 => branch_target,
            sel    => pc_src,
            output => next_pc
        );

    -- Register read and immediate generation
    u_register_file : entity work.register_file(rtl)
        port map (
            clk        => clk,
            write_en   => reg_write,
            rs1_addr   => instruction_i(19 downto 15),
            rs2_addr   => instruction_i(24 downto 20),
            rd_addr    => instruction_i(11 downto 7),
            write_data => write_back_data,
            rs1_data   => read_data_1,
            rs2_data   => read_data_2
        );

    u_immediate_generator : entity work.immediate_generator(rtl)
        port map (
            instruction => instruction_i,
            immediate   => immediate
        );

    -- Execution and data memory access
    u_alu_operand_mux : entity work.mux2(rtl)
        port map (
            input0 => read_data_2,
            input1 => immediate,
            sel    => alu_src,
            output => alu_operand_b
        );

    u_alu : entity work.alu(rtl)
        port map (
            a           => read_data_1,
            b           => alu_operand_b,
            alu_control => alu_control,
            result      => alu_result,
            zero        => zero
        );

    u_data_memory : entity work.data_memory(rtl)
        port map (
            clk        => clk,
            mem_read   => mem_read,
            mem_write  => mem_write,
            address     => alu_result,
            write_data => read_data_2,
            read_data  => memory_data
        );

    -- Write-back to the register file
    u_write_back_mux : entity work.mux2(rtl)
        port map (
            input0 => alu_result,
            input1 => memory_data,
            sel    => mem_to_reg,
            output => write_back_data
        );

    instruction <= instruction_i;
end architecture;
