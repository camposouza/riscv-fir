library ieee;
use ieee.std_logic_1164.all;

entity hazard_detection_unit is
    port (
        id_ex_mem_read : in  std_logic;
        id_ex_rd_addr  : in  std_logic_vector(4 downto 0);
        if_id_rs1_addr : in  std_logic_vector(4 downto 0);
        if_id_rs2_addr : in  std_logic_vector(4 downto 0);
        branch_taken   : in  std_logic;

        pc_write       : out std_logic;
        if_id_write    : out std_logic;
        if_id_flush    : out std_logic;
        id_ex_flush    : out std_logic
    );
end entity;

architecture rtl of hazard_detection_unit is
    signal load_use_hazard : std_logic;
begin
    load_use_hazard <= '1' when id_ex_mem_read = '1' and
                                id_ex_rd_addr /= "00000" and
                                (id_ex_rd_addr = if_id_rs1_addr or
                                 id_ex_rd_addr = if_id_rs2_addr)
                       else '0';

    -- Stalling holds IF and ID while a bubble is inserted into EX.
    pc_write <= not load_use_hazard;
    if_id_write <= not load_use_hazard;

    -- Branches are predicted not taken and resolved in EX.
    -- On a taken   branch, both younger instructions must be discarded.
    if_id_flush <= branch_taken;
    id_ex_flush <= load_use_hazard or branch_taken;
end architecture;
