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
    signal pc_write, if_id_write, if_id_flush, id_ex_flush : std_logic;
    signal forward_a, forward_b : std_logic_vector(1 downto 0);
    signal if_id_rs1_addr, if_id_rs2_addr : std_logic_vector(4 downto 0);
    signal id_ex_mem_read : std_logic;
    signal id_ex_rd_addr, id_ex_rs1_addr, id_ex_rs2_addr : std_logic_vector(4 downto 0);
    signal ex_mem_reg_write, ex_mem_mem_to_reg : std_logic;
    signal ex_mem_rd_addr, mem_wb_rd_addr : std_logic_vector(4 downto 0);
    signal mem_wb_reg_write, branch_taken : std_logic;
begin

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
            pc_write    => pc_write,
            if_id_write => if_id_write,
            if_id_flush => if_id_flush,
            id_ex_flush => id_ex_flush,
            forward_a   => forward_a,
            forward_b   => forward_b,
            instruction => instruction,
            zero        => zero,
            if_id_rs1_addr_o => if_id_rs1_addr,
            if_id_rs2_addr_o => if_id_rs2_addr,
            id_ex_mem_read_o => id_ex_mem_read,
            id_ex_rd_addr_o => id_ex_rd_addr,
            id_ex_rs1_addr_o => id_ex_rs1_addr,
            id_ex_rs2_addr_o => id_ex_rs2_addr,
            ex_mem_reg_write_o => ex_mem_reg_write,
            ex_mem_mem_to_reg_o => ex_mem_mem_to_reg,
            ex_mem_rd_addr_o => ex_mem_rd_addr,
            mem_wb_reg_write_o => mem_wb_reg_write,
            mem_wb_rd_addr_o => mem_wb_rd_addr,
            branch_taken_o => branch_taken
        );

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

    u_hazard_detection_unit : entity work.hazard_detection_unit(rtl)
        port map (
            id_ex_mem_read => id_ex_mem_read,
            id_ex_rd_addr => id_ex_rd_addr,
            if_id_rs1_addr => if_id_rs1_addr,
            if_id_rs2_addr => if_id_rs2_addr,
            branch_taken => branch_taken,
            pc_write => pc_write,
            if_id_write => if_id_write,
            if_id_flush => if_id_flush,
            id_ex_flush => id_ex_flush
        );

    u_forwarding_unit : entity work.forwarding_unit(rtl)
        port map (
            ex_mem_reg_write => ex_mem_reg_write,
            ex_mem_mem_to_reg => ex_mem_mem_to_reg,
            ex_mem_rd_addr => ex_mem_rd_addr,
            mem_wb_reg_write => mem_wb_reg_write,
            mem_wb_rd_addr => mem_wb_rd_addr,
            id_ex_rs1_addr => id_ex_rs1_addr,
            id_ex_rs2_addr => id_ex_rs2_addr,
            forward_a => forward_a,
            forward_b => forward_b
        );
end architecture;
