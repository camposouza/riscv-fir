    constant ROM : memory_t := (
        0 => x"00A00093", -- addi x1, x0, 10
        1 => x"01400113", -- addi x2, x0, 20
        2 => x"002081B3", -- add  x3, x1, x2
        3 => x"00302023", -- sw   x3, 0(x0)
        4 => x"00002203", -- lw   x4, 0(x0)
        5 => x"00418463", -- beq  x3, x4, OK
        6 => x"00100293", -- addi x5, x0, 1 (deve ser ignorada)
        7 => x"02A00313", -- OK: addi x6, x0, 42
        others => x"00000013" -- nop
    );