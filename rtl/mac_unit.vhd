library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Multiply-accumulate unit of the MEM stage, used by macdm:
-- result = accumulator + coefficient * sample (low 64 bits, like mul).
entity mac_unit is
    port (
        accumulator : in  std_logic_vector(63 downto 0);
        coefficient : in  std_logic_vector(63 downto 0);
        sample      : in  std_logic_vector(63 downto 0);

        result      : out std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of mac_unit is
begin
    result <= std_logic_vector(
        signed(accumulator) + resize(signed(coefficient) * signed(sample), 64)
    );
end architecture;
