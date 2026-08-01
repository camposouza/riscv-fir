library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
    port (
        a      : in  std_logic_vector(63 downto 0);
        b      : in  std_logic_vector(63 downto 0);

        result : out std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of adder is

begin

    result <= std_logic_vector(signed(a) + signed(b));

end architecture;