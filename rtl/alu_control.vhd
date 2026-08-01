library ieee;
use ieee.std_logic_1164.all;

entity alu_control is
    port (
        alu_op      : in  std_logic_vector(1 downto 0);
        funct3      : in  std_logic_vector(2 downto 0);
        funct7      : in  std_logic_vector(6 downto 0);

        alu_control : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of alu_control is

begin

    process(alu_op, funct3, funct7)
    begin

        case alu_op is

            -- Load / Store -> ADD
            when "00" =>
                alu_control <= "0010";

            -- Branch -> SUB
            when "01" =>
                alu_control <= "0110";

            -- R-type
            when "10" =>

                case funct3 is

                    -- ADD / SUB
                    when "000" =>
                        if funct7 = "0000000" then
                            alu_control <= "0010"; -- ADD
                        elsif funct7 = "0100000" then
                            alu_control <= "0110"; -- SUB
                        else
                            alu_control <= "0000";
                        end if;

                    -- AND
                    when "111" =>
                        alu_control <= "0000";

                    -- OR
                    when "110" =>
                        alu_control <= "0001";

                    when others =>
                        alu_control <= "0000";
                end case;

            when others =>
                alu_control <= "0000";
        end case;
    end process;
end architecture;