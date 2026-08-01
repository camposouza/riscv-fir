library ieee;
use ieee.std_logic_1164.all;

entity riscv_core is
    port (
        clk   : in std_logic;
        reset : in std_logic
    );
end entity;

architecture rtl of riscv_core is
    signal instruction        : std_logic_vector(31 downto 0);
    signal zero               : std_logic;
    signal pc_src             : std_logic;
    signal mem_read           : std_logic;
    signal mem_to_reg         : std_logic;
    signal mem_write          : std_logic;
    signal alu_src            : std_logic;
    signal reg_write          : std_logic;
    signal alu_control_signal : std_logic_vector(3 downto 0);
begin
    -- Datapath receives control signals and provides the instruction and zero flag.
    u_datapath : entity work.datapath(structural)
        port map (
            clk         => clk,
            reset       => reset,
            pc_src      => pc_src,
            mem_read    => mem_read,
            mem_to_reg  => mem_to_reg,
            mem_write   => mem_write,
            alu_src     => alu_src,
            reg_write   => reg_write,
            alu_control => alu_control_signal,
            instruction => instruction,
            zero        => zero
        );

    -- Main control unit decodes the opcode and the branch condition.
    u_control_unit : entity work.control_unit(rtl)
        port map (
            opcode     => instruction(6 downto 0),
            zero       => zero,
            pc_src     => pc_src,
            mem_read   => mem_read,
            mem_to_reg => mem_to_reg,
            funct3     => instruction(14 downto 12),
            funct7     => instruction(31 downto 25),
            mem_write  => mem_write,
            alu_src    => alu_src,
            reg_write  => reg_write,
            alu_control => alu_control_signal
        );
end architecture;
