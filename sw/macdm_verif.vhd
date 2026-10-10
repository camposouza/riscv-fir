constant ROM : memory_t := (
    -- Setup: samples in data memory
    0  => x"00B00093", -- addi  x1,  x0, 11
    1  => x"00102023", -- sw    x1,  0(x0)       Mem[0]  = 11
    2  => x"01000093", -- addi  x1,  x0, 16
    3  => x"00102423", -- sw    x1,  8(x0)       Mem[1]  = 16
    4  => x"00400093", -- addi  x1,  x0, 4
    5  => x"02102023", -- sw    x1,  32(x0)      Mem[4]  = 4
    6  => x"00600093", -- addi  x1,  x0, 6
    7  => x"02102423", -- sw    x1,  40(x0)      Mem[5]  = 6
    8  => x"00A00093", -- addi  x1,  x0, 10
    9  => x"04102023", -- sw    x1,  64(x0)      Mem[8]  = 10
    10 => x"00700093", -- addi  x1,  x0, 7
    11 => x"06102823", -- sw    x1,  112(x0)     Mem[14] = 7
    12 => x"00100093", -- addi  x1,  x0, 1
    13 => x"0A102023", -- sw    x1,  160(x0)     Mem[20] = 1
    14 => x"00200093", -- addi  x1,  x0, 2
    15 => x"0A102423", -- sw    x1,  168(x0)     Mem[21] = 2
    16 => x"00300093", -- addi  x1,  x0, 3
    17 => x"0A102823", -- sw    x1,  176(x0)     Mem[22] = 3
    18 => x"03200093", -- addi  x1,  x0, 50
    19 => x"0C102023", -- sw    x1,  192(x0)     Mem[24] = 50

    -- 1. Accumulator from ALU / previous macdm; reads the word just moved
    20 => x"00200A13", -- addi  x20, x0, 2
    21 => x"00500A93", -- addi  x21, x0, 5
    22 => x"01400A8B", -- macdm x21, x20, 0(x0)  x21 = 27, Mem[1] <- 11
    23 => x"03400A8B", -- macdm x21, x20, 1(x0)  x21 = 49, Mem[2] <- 11

    -- 2. Coefficient loaded by the previous lw
    24 => x"02002B03", -- lw    x22, 32(x0)
    25 => x"0B600A8B", -- macdm x21, x22, 5(x0)  x21 = 73, Mem[6] <- 6 (stall)

    -- 3. Accumulator at distance 2
    26 => x"00300B93", -- addi  x23, x0, 3
    27 => x"11700A8B", -- macdm x21, x23, 8(x0)  x21 = 103, Mem[9] <- 10

    -- 4. lw of the moved word; accumulator from that lw
    28 => x"04802C03", -- lw    x24, 72(x0)      x24 = 10
    29 => x"13700C0B", -- macdm x24, x23, 9(x0)  x24 = 40, Mem[10] <- 10

    -- 5. Ordinary consumer of a macdm result
    30 => x"015C0CB3", -- add   x25, x24, x21    x25 = 143 (stall)

    -- 6. Forwarded base, nonzero offset; sw over the moved word
    31 => x"06000D13", -- addi  x26, x0, 96
    32 => x"054D0D8B", -- macdm x27, x20, 2(x26) x27 = 14, Mem[15] <- 7
    33 => x"07B02C23", -- sw    x27, 120(x0)     Mem[15] = 14 (stall)

    -- 7. macdm right after sw to the word it reads
    34 => x"00D00093", -- addi  x1,  x0, 13
    35 => x"08102023", -- sw    x1,  128(x0)     Mem[16] = 13
    36 => x"20100E0B", -- macdm x28, x1,  16(x0) x28 = 169, Mem[17] <- 13

    -- 8. Delay line shifted right
    37 => x"2D400F0B", -- macdm x30, x20, 22(x0) x30 = 6,  Mem[23] <- 3
    38 => x"2B700F0B", -- macdm x30, x23, 21(x0) x30 = 12, Mem[22] <- 2
    39 => x"29600F0B", -- macdm x30, x22, 20(x0) x30 = 16, Mem[21] <- 1

    -- 9. macdm in the shadow of a taken branch
    40 => x"00000663", -- beq   x0,  x0, DONE
    41 => x"31400A8B", -- macdm x21, x20, 24(x0) (flush)
    42 => x"31400A8B", -- macdm x21, x20, 24(x0) (flush)
    43 => x"05500F93", -- addi  x31, x0, 85      DONE

    others => x"00000013" -- nop
);
