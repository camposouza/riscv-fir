library ieee;
use ieee.std_logic_1164.all;

-- Selects the two ALU forwarding multiplexers used in the EX stage.
-- 00: ID/EX register value; 10: EX/MEM ALU result; 01: MEM/WB write-back.
entity forwarding_unit is
    port (
        ex_mem_reg_write  : in  std_logic;
        ex_mem_mem_to_reg : in  std_logic;
        ex_mem_rd_addr    : in  std_logic_vector(4 downto 0);
        mem_wb_reg_write  : in  std_logic;
        mem_wb_rd_addr    : in  std_logic_vector(4 downto 0);
        id_ex_rs1_addr    : in  std_logic_vector(4 downto 0);
        id_ex_rs2_addr    : in  std_logic_vector(4 downto 0);

        forward_a         : out std_logic_vector(1 downto 0);
        forward_b         : out std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of forwarding_unit is
begin
    process(ex_mem_reg_write, ex_mem_mem_to_reg, ex_mem_rd_addr,
            mem_wb_reg_write, mem_wb_rd_addr, id_ex_rs1_addr, id_ex_rs2_addr)
    begin
        forward_a <= "00";
        forward_b <= "00";

        -- A load in EX/MEM cannot be forwarded to EX: its data becomes
        -- available only at MEM/WB after the HDU's one-cycle load-use stall.
        if ex_mem_reg_write = '1' and ex_mem_mem_to_reg = '0' and
           ex_mem_rd_addr /= "00000" then
            if ex_mem_rd_addr = id_ex_rs1_addr then
                forward_a <= "10";
            end if;
            if ex_mem_rd_addr = id_ex_rs2_addr then
                forward_b <= "10";
            end if;
        end if;

        -- EX/MEM has priority over MEM/WB when both write the same register.
        if mem_wb_reg_write = '1' and mem_wb_rd_addr /= "00000" then
            if mem_wb_rd_addr = id_ex_rs1_addr and
               not (ex_mem_reg_write = '1' and ex_mem_mem_to_reg = '0' and
                    ex_mem_rd_addr /= "00000" and ex_mem_rd_addr = id_ex_rs1_addr) then
                forward_a <= "01";
            end if;
            if mem_wb_rd_addr = id_ex_rs2_addr and
               not (ex_mem_reg_write = '1' and ex_mem_mem_to_reg = '0' and
                    ex_mem_rd_addr /= "00000" and ex_mem_rd_addr = id_ex_rs2_addr) then
                forward_b <= "01";
            end if;
        end if;
    end process;
end architecture;
