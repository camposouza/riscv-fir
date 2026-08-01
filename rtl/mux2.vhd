library ieee;
use ieee.std_logic_1164.all;

entity mux2 is
    port (
        input0 : in  std_logic_vector(63 downto 0);
        input1 : in  std_logic_vector(63 downto 0);
        sel    : in  std_logic;

        output : out std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of mux2 is

begin

    output <= input0 when sel = '0'
              else input1;

end architecture;