library ieee;
use ieee.std_logic_1164.all;

entity ex_mem_register is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        mem_to_reg_i     : in  std_logic;
        reg_write_i      : in  std_logic;
        branch_i         : in  std_logic;
        mem_read_i       : in  std_logic;
        mem_write_i      : in  std_logic;
        zero_i           : in  std_logic;
        branch_target_i  : in  std_logic_vector(63 downto 0);
        alu_result_i     : in  std_logic_vector(63 downto 0);
        write_data_i     : in  std_logic_vector(63 downto 0);
        rd_addr_i        : in  std_logic_vector(4 downto 0);

        mem_to_reg_o     : out std_logic;
        reg_write_o      : out std_logic;
        branch_o         : out std_logic;
        mem_read_o       : out std_logic;
        mem_write_o      : out std_logic;
        zero_o           : out std_logic;
        branch_target_o  : out std_logic_vector(63 downto 0);
        alu_result_o     : out std_logic_vector(63 downto 0);
        write_data_o     : out std_logic_vector(63 downto 0);
        rd_addr_o        : out std_logic_vector(4 downto 0)
    );
end entity;

architecture rtl of ex_mem_register is
    signal control_reg : std_logic_vector(4 downto 0) := (others => '0');
    signal zero_reg : std_logic := '0';
    signal branch_target_reg, alu_result_reg, write_data_reg : std_logic_vector(63 downto 0) := (others => '0');
    signal rd_addr_reg : std_logic_vector(4 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                control_reg <= (others => '0');
                zero_reg <= '0';
                branch_target_reg <= (others => '0');
                alu_result_reg <= (others => '0');
                write_data_reg <= (others => '0');
                rd_addr_reg <= (others => '0');
            else
                control_reg <= mem_to_reg_i & reg_write_i & branch_i & mem_read_i & mem_write_i;
                zero_reg <= zero_i;
                branch_target_reg <= branch_target_i;
                alu_result_reg <= alu_result_i;
                write_data_reg <= write_data_i;
                rd_addr_reg <= rd_addr_i;
            end if;
        end if;
    end process;

    mem_to_reg_o <= control_reg(4);
    reg_write_o <= control_reg(3);
    branch_o <= control_reg(2);
    mem_read_o <= control_reg(1);
    mem_write_o <= control_reg(0);
    zero_o <= zero_reg;
    branch_target_o <= branch_target_reg;
    alu_result_o <= alu_result_reg;
    write_data_o <= write_data_reg;
    rd_addr_o <= rd_addr_reg;
end architecture;
