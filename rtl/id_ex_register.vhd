library ieee;
use ieee.std_logic_1164.all;

entity id_ex_register is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        flush          : in  std_logic;

        -- WB control
        mem_to_reg_i   : in  std_logic;
        reg_write_i    : in  std_logic;
        -- M control
        branch_i       : in  std_logic;
        mem_read_i     : in  std_logic;
        mem_write_i    : in  std_logic;
        -- EX control
        alu_src_i      : in  std_logic;
        alu_control_i  : in  std_logic_vector(3 downto 0);

        pc_plus_4_i    : in  std_logic_vector(63 downto 0);
        read_data_1_i  : in  std_logic_vector(63 downto 0);
        read_data_2_i  : in  std_logic_vector(63 downto 0);
        immediate_i    : in  std_logic_vector(63 downto 0);
        rs1_addr_i     : in  std_logic_vector(4 downto 0);
        rs2_addr_i     : in  std_logic_vector(4 downto 0);
        rd_addr_i      : in  std_logic_vector(4 downto 0);

        mem_to_reg_o   : out std_logic;
        reg_write_o    : out std_logic;
        branch_o       : out std_logic;
        mem_read_o     : out std_logic;
        mem_write_o    : out std_logic;
        alu_src_o      : out std_logic;
        alu_control_o  : out std_logic_vector(3 downto 0);
        pc_plus_4_o    : out std_logic_vector(63 downto 0);
        read_data_1_o  : out std_logic_vector(63 downto 0);
        read_data_2_o  : out std_logic_vector(63 downto 0);
        immediate_o    : out std_logic_vector(63 downto 0);
        rs1_addr_o     : out std_logic_vector(4 downto 0);
        rs2_addr_o     : out std_logic_vector(4 downto 0);
        rd_addr_o      : out std_logic_vector(4 downto 0)
    );
end entity;

architecture rtl of id_ex_register is
    signal control_reg : std_logic_vector(9 downto 0) := (others => '0');
    signal pc_plus_4_reg, read_data_1_reg, read_data_2_reg, immediate_reg : std_logic_vector(63 downto 0) := (others => '0');
    signal rs1_addr_reg, rs2_addr_reg, rd_addr_reg : std_logic_vector(4 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or flush = '1' then
                control_reg <= (others => '0');
                pc_plus_4_reg <= (others => '0');
                read_data_1_reg <= (others => '0');
                read_data_2_reg <= (others => '0');
                immediate_reg <= (others => '0');
                rs1_addr_reg <= (others => '0');
                rs2_addr_reg <= (others => '0');
                rd_addr_reg <= (others => '0');
            else
                control_reg <= mem_to_reg_i & reg_write_i & branch_i & mem_read_i & mem_write_i & alu_src_i & alu_control_i;
                pc_plus_4_reg <= pc_plus_4_i;
                read_data_1_reg <= read_data_1_i;
                read_data_2_reg <= read_data_2_i;
                immediate_reg <= immediate_i;
                rs1_addr_reg <= rs1_addr_i;
                rs2_addr_reg <= rs2_addr_i;
                rd_addr_reg <= rd_addr_i;
            end if;
        end if;
    end process;

    mem_to_reg_o <= control_reg(9);
    reg_write_o <= control_reg(8);
    branch_o <= control_reg(7);
    mem_read_o <= control_reg(6);
    mem_write_o <= control_reg(5);
    alu_src_o <= control_reg(4);
    alu_control_o <= control_reg(3 downto 0);
    pc_plus_4_o <= pc_plus_4_reg;
    read_data_1_o <= read_data_1_reg;
    read_data_2_o <= read_data_2_reg;
    immediate_o <= immediate_reg;
    rs1_addr_o <= rs1_addr_reg;
    rs2_addr_o <= rs2_addr_reg;
    rd_addr_o <= rd_addr_reg;
end architecture;
