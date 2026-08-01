library ieee;
use ieee.std_logic_1164.all;

-- Types shared by the RTL and white-box testbenches.
package riscv_debug_types is
    type register_array_t is array (0 to 31) of std_logic_vector(63 downto 0);
    type data_memory_array_t is array (0 to 255) of std_logic_vector(63 downto 0);
end package;

package body riscv_debug_types is
end package body;
