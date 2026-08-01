library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_debug_types.all;

entity data_memory is
    port (
        clk         : in  std_logic;
        mem_read    : in  std_logic;
        mem_write   : in  std_logic;

        address     : in  std_logic_vector(63 downto 0);
        write_data  : in  std_logic_vector(63 downto 0);

        read_data   : out std_logic_vector(63 downto 0)
    );
end entity;

architecture rtl of data_memory is

    signal memory : data_memory_array_t := (others => (others => '0'));

begin

    -- Asynchronous read.
    read_data <= memory(to_integer(unsigned(address(10 downto 3))))
                 when mem_read = '1'
                 else (others => '0');

    -- Synchronous write
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_write = '1' then
                memory(to_integer(unsigned(address(10 downto 3)))) <= write_data;
            end if;
        end if;
    end process;
end architecture;
