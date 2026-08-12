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
    0  => x"00A00093", -- addi x1,  x0, 10
    1  => x"00300113", -- addi x2,  x0, 3
    2  => x"002081B3", -- add  x3,  x1, x2
    3  => x"40218233", -- sub  x4,  x3, x2
    4  => x"001272B3", -- and  x5,  x4, x1
    5  => x"0022E333", -- or   x6,  x5, x2
    6  => x"00602023", -- sw   x6,  0(x0)
    7  => x"00002383", -- lw   x7,  0(x0)
    8  => x"00138413", -- addi x8,  x7, 1
    9  => x"007404B3", -- add  x9,  x8, x7
    10 => x"00948663", -- beq  x9,  x9, TAKEN_1
    11 => x"06F00513", -- addi x10, x0, 111 (flush)
    12 => x"0DE00593", -- addi x11, x0, 222 (flush)
    13 => x"00848463", -- beq  x9,  x8, AFTER_NOT_TAKEN
    14 => x"00700613", -- addi x12, x0, 7
    15 => x"01000693", -- addi x13, x0, 16
    16 => x"00D02423", -- sw   x13, 8(x0)
    17 => x"00802703", -- lw   x14, 8(x0)
    18 => x"00D70663", -- beq  x14, x13, TAKEN_2
    19 => x"00100813", -- addi x16, x0, 1 (flush)
    20 => x"00100893", -- addi x17, x0, 1 (flush)
    21 => x"001707B3", -- add  x15, x14, x1
    22 => x"00F78663", -- beq  x15, x15, PASS
    23 => x"00100913", -- addi x18, x0, 1 (flush)
    24 => x"00100993", -- addi x19, x0, 1 (flush)
    25 => x"05500F93", -- addi x31, x0, 85
    others => x"00000013" -- nop
);
begin

    instruction <= ROM(to_integer(unsigned(address(9 downto 2))));

end architecture;