library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_debug_types.all;

entity register_file is
    port (
	     clk        : in  std_logic;
		  write_en   : in  std_logic;
		  
		  rs1_addr   : in  std_logic_vector(4 downto 0);
		  rs2_addr   : in  std_logic_vector(4 downto 0);
		  rd_addr    : in  std_logic_vector(4 downto 0);
		  
		  write_data : in  std_logic_vector(63 downto 0);
		  
		  rs1_data   : out std_logic_vector(63 downto 0);
		  rs2_data   : out std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of register_file is

    signal registers : register_array_t := (others => (others => '0'));

begin
	 
	 -- Asynchronous reading
    rs1_data <= registers(to_integer(unsigned(rs1_addr)));
    rs2_data <= registers(to_integer(unsigned(rs2_addr)));
	 
	 -- Synchronous writing
    process(clk)
    begin
        if rising_edge(clk) then
	         if write_en = '1' then
		          if rd_addr /= "00000" then
				        registers(to_integer(unsigned(rd_addr))) <= write_data;
			       end if;
	         end if;
        end if;
    end process;
end architecture;
