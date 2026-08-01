library ieee;
use ieee.std_logic_1164.all;

entity control_unit is
    port (
        opcode      : in  std_logic_vector(6 downto 0);
        zero        : in  std_logic;
        funct3      : in  std_logic_vector(2 downto 0);
        funct7      : in  std_logic_vector(6 downto 0);
        
        pc_src      : out std_logic;
        mem_read    : out std_logic;
        mem_to_reg  : out std_logic;
        mem_write   : out std_logic;
        alu_src     : out std_logic;
        reg_write   : out std_logic;
        alu_control : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of control_unit is

    signal branch : std_logic;
    signal alu_op : std_logic_vector(1 downto 0);

begin

    -- Branch decision
    pc_src <= branch and zero;

    -- ALU control refines alu_op using the instruction function fields.
    u_alu_control : entity work.alu_control(rtl)
        port map (
            alu_op      => alu_op,
            funct3      => funct3,
            funct7      => funct7,
            alu_control => alu_control
        );

    process(opcode)
    begin

        -- Default values
        branch     <= '0';
        mem_read   <= '0';
        mem_to_reg <= '0';
        alu_op     <= "00";
        mem_write  <= '0';
        alu_src    <= '0';
        reg_write  <= '0';

        case opcode is

            -- lw
            when "0000011" =>
                mem_read   <= '1';
                mem_to_reg <= '1';
                alu_op     <= "00";
                alu_src    <= '1';
                reg_write  <= '1';

            -- addi
            when "0010011" =>
                alu_op    <= "00";
                alu_src   <= '1';
                reg_write <= '1';

            -- sw
            when "0100011" =>
                mem_write  <= '1';
                alu_op     <= "00";
                alu_src    <= '1';

            -- beq
            when "1100011" =>
                branch <= '1';
                alu_op <= "01";

            -- R-type (add, sub, and, or)
            when "0110011" =>
                alu_op    <= "10";
                reg_write <= '1';

            when others =>
                null;

        end case;
    end process;

end architecture;
