library ieee;
use ieee.std_logic_1164.all;

entity if_id_register is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        write_en      : in  std_logic;
        flush         : in  std_logic;
        pc_plus_4_i   : in  std_logic_vector(63 downto 0);
        instruction_i : in  std_logic_vector(31 downto 0);

        pc_plus_4_o   : out std_logic_vector(63 downto 0);
        instruction_o : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of if_id_register is
    signal pc_plus_4_reg : std_logic_vector(63 downto 0) := (others => '0');
    signal instruction_reg : std_logic_vector(31 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' or flush = '1' then
                pc_plus_4_reg <= (others => '0');
                instruction_reg <= (others => '0');
            elsif write_en = '1' then
                pc_plus_4_reg <= pc_plus_4_i;
                instruction_reg <= instruction_i;
            end if;
        end if;
    end process;

    pc_plus_4_o <= pc_plus_4_reg;
    instruction_o <= instruction_reg;
end architecture;
