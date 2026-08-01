library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_memory is
    port (
        address     : in  std_logic_vector(63 downto 0);
        instruction : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of instruction_memory is

    type memory_t is array (0 to 255) of std_logic_vector(31 downto 0);
	     
    constant ROM : memory_t := (
        0 => x"00A00093", -- addi x1, x0, 10
        1 => x"01400113", -- addi x2, x0, 20
        2 => x"002081B3", -- add  x3, x1, x2
        3 => x"00302023", -- sw   x3, 0(x0)
        4 => x"00002203", -- lw   x4, 0(x0)
        5 => x"00418463", -- beq  x3, x4, OK
        6 => x"00100293", -- NOT EXECUTED
        7 => x"02A00313", -- OK: addi x6, x0, 42
        others => x"00000013" -- nop
    );

begin

    instruction <= ROM(to_integer(unsigned(address(9 downto 2))));

end architecture;