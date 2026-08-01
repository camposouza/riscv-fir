library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity immediate_generator is
    port (
        instruction : in  std_logic_vector(31 downto 0);
        immediate   : out std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of immediate_generator is

    signal opcode : std_logic_vector(6 downto 0);
	 
begin

    opcode <= instruction(6 downto 0);
	 
	 process(instruction, opcode)
	 begin
	     
		  case opcode is
		  
            -- I-type
            when "0000011" | "0010011" =>
                immediate <= std_logic_vector(
                    resize(
                        signed(instruction(31 downto 20)),
                        64
                    )
                );

            -- S-type
            when "0100011" =>
                immediate <= std_logic_vector(
                    resize(
                        signed(instruction(31 downto 25) &
                               instruction(11 downto 7)),
                        64
                    )
                );

            -- B-type
            when "1100011" =>
                immediate <= std_logic_vector(
                    resize(
                        signed(
                            instruction(31) &
                            instruction(7) &
                            instruction(30 downto 25) &
                            instruction(11 downto 8) &
                            '0'
                        ),
                        64
                    )
                );

            when others =>
                immediate <= (others => '0');
					 
        end case;
    end process;
end architecture;
