library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (
	     a           : in  std_logic_vector(63 downto 0);
		  b           : in  std_logic_vector(63 downto 0);
		  alu_control : in  std_logic_vector(3 downto 0);
		  
		  result      : out std_logic_vector(63 downto 0);
		  zero        : out std_logic
	 );
end entity;

architecture rtl of alu is

    signal alu_result : std_logic_vector(63 downto 0);
	 
begin

    process(a, b, alu_control)
	 begin
	     case alu_control is
		      
				-- AND
				when "0000" =>
				    alu_result <= a and b;
					 
				-- OR
				when "0001" =>
				    alu_result <= a or b;
				
				-- ADD
				when "0010" =>
				    alu_result <= std_logic_vector(signed(a) + signed(b));
					 
				-- SUB
				when "0110" =>
				    alu_result <= std_logic_vector(signed(a) - signed(b));
					 
				when others =>
                alu_result <= (others => '0');
        end case;
    end process;

    result <= alu_result;

    zero <= '1' when alu_result = x"0000000000000000"
            else '0';
end architecture;
	 