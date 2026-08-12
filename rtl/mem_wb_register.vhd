library ieee;
use ieee.std_logic_1164.all;

entity mem_wb_register is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        mem_to_reg_i   : in  std_logic;
        reg_write_i    : in  std_logic;
        memory_data_i  : in  std_logic_vector(63 downto 0);
        alu_result_i   : in  std_logic_vector(63 downto 0);
        rd_addr_i      : in  std_logic_vector(4 downto 0);

        mem_to_reg_o   : out std_logic;
        reg_write_o    : out std_logic;
        memory_data_o  : out std_logic_vector(63 downto 0);
        alu_result_o   : out std_logic_vector(63 downto 0);
        rd_addr_o      : out std_logic_vector(4 downto 0)
    );
end entity;

architecture rtl of mem_wb_register is
    signal mem_to_reg_reg, reg_write_reg : std_logic := '0';
    signal memory_data_reg, alu_result_reg : std_logic_vector(63 downto 0) := (others => '0');
    signal rd_addr_reg : std_logic_vector(4 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mem_to_reg_reg <= '0';
                reg_write_reg <= '0';
                memory_data_reg <= (others => '0');
                alu_result_reg <= (others => '0');
                rd_addr_reg <= (others => '0');
            else
                mem_to_reg_reg <= mem_to_reg_i;
                reg_write_reg <= reg_write_i;
                memory_data_reg <= memory_data_i;
                alu_result_reg <= alu_result_i;
                rd_addr_reg <= rd_addr_i;
            end if;
        end if;
    end process;

    mem_to_reg_o <= mem_to_reg_reg;
    reg_write_o <= reg_write_reg;
    memory_data_o <= memory_data_reg;
    alu_result_o <= alu_result_reg;
    rd_addr_o <= rd_addr_reg;
end architecture;
