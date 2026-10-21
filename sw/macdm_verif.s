# macdm verification.
#
# macdm rd, rs2, off(rs1)  ->  rd <= rd + rs2 * Mem[A],  Mem[A+8] <= Mem[A],
#                              A = rs1 + off*8
#   rd: accumulator (read in ID through the 3rd register-file port), rs1: base,
#   rs2: coefficient. The MAC and the data move both happen in MEM.
#
# Each block triggers one mechanism added (or reused) for macdm: register
# forwarding/stalls/flushes, and the ordering of the data move against the
# memory accesses around it. Checked by tb/macdm_verif_tb.vhd.
#
# Data memory map (word index = byte address / 8), initial -> final:
#   Mem[0-2]   11, 16, 0  -> 11, 11, 11   block 1 (ascending, back-to-back)
#   Mem[4-6]   4, 6, 0    -> 4, 6, 6      block 2
#   Mem[8-10]  10, 0, 0   -> 10, 10, 10   blocks 3 and 4
#   Mem[14-15] 7, 0       -> 7, 14        block 6 (sw after the move wins)
#   Mem[16-17] 0, 0       -> 13, 13       block 7 (sw before macdm)
#   Mem[20-23] 1, 2, 3, 0 -> 1, 1, 2, 3   block 8 (delay line shifted right)
#   Mem[24-25] 50, 0      -> 50, 0        block 9 (flushed macdm must not move)

# Setup: samples in data memory
addi  x1,  x0, 11
sw    x1,  0(x0)          # Mem[0]  = 11
addi  x1,  x0, 16
sw    x1,  8(x0)          # Mem[1]  = 16
addi  x1,  x0, 4
sw    x1,  32(x0)         # Mem[4]  = 4
addi  x1,  x0, 6
sw    x1,  40(x0)         # Mem[5]  = 6
addi  x1,  x0, 10
sw    x1,  64(x0)         # Mem[8]  = 10
addi  x1,  x0, 7
sw    x1,  112(x0)        # Mem[14] = 7
addi  x1,  x0, 1
sw    x1,  160(x0)        # Mem[20] = 1
addi  x1,  x0, 2
sw    x1,  168(x0)        # Mem[21] = 2
addi  x1,  x0, 3
sw    x1,  176(x0)        # Mem[22] = 3
addi  x1,  x0, 50
sw    x1,  192(x0)        # Mem[24] = 50

# 1. Accumulator from an ALU instruction and from the previous macdm (distance 1);
#    the 2nd macdm reads the word the 1st one has just moved
addi  x20, x0, 2          # x20 = 2 (coefficient)
addi  x21, x0, 5          # x21 = 5 (accumulator)
macdm x21, x20, 0(x0)     # x21 = 5 + 2*11 = 27;  Mem[1] <- 11; acc x21 <- MEM/WB->MEM (forward_m); coef x20 <- MEM/WB
macdm x21, x20, 1(x0)     # x21 = 27 + 2*11 = 49; Mem[2] <- 11; reads the moved Mem[1] (16 without the move);
                          #   acc x21 <- MEM/WB->MEM (forward_m, macdm producer)

# 2. Coefficient loaded by the previous lw
lw    x22, 32(x0)         # x22 = 4
macdm x21, x22, 5(x0)     # x21 = 49 + 4*6 = 73;  Mem[6] <- 6; STALL 1 cycle (coef from lw), then coef x22 <- MEM/WB;
                          #   acc x21 via 3rd-port write-first bypass

# 3. Accumulator at distance 2
addi  x23, x0, 3          # x23 = 3
macdm x21, x23, 8(x0)     # x21 = 73 + 3*10 = 103; Mem[9] <- 10; acc x21 <- MEM/WB->EX (forward_c); coef x23 <- EX/MEM

# 4. lw right after macdm reads the moved word; accumulator from that lw (no stall)
lw    x24, 72(x0)         # x24 = Mem[9] = 10 (0 without the move)
macdm x24, x23, 9(x0)     # x24 = 10 + 3*10 = 40; Mem[10] <- 10; acc x24 <- MEM/WB->MEM (forward_m, load producer)

# 5. Ordinary consumer of a macdm result
add   x25, x24, x21       # x25 = 40 + 103 = 143; STALL 1 cycle, then x24 <- MEM/WB

# 6. Base register produced by the previous instruction, nonzero offset;
#    sw right after macdm to the word it moved into
addi  x26, x0, 96         # x26 = 96
macdm x27, x20, 2(x26)    # A = 96 + 2*8 = 112: x27 = 0 + 2*7 = 14; Mem[15] <- 7; base x26 <- EX/MEM
sw    x27, 120(x0)        # Mem[15] = 14 (overwrites the move); STALL 1 cycle, then x27 <- MEM/WB

# 7. macdm right after sw to the word it reads
addi  x1,  x0, 13         # x1 = 13
sw    x1,  128(x0)        # Mem[16] = 13; data x1 <- EX/MEM
macdm x28, x1,  16(x0)    # x28 = 0 + 13*13 = 169; Mem[17] <- 13; coef x1 <- MEM/WB

# 8. Delay line, as in the FIR: newest-to-oldest, each macdm shifts its sample right
macdm x30, x20, 22(x0)    # x30 = 0 + 2*3 = 6;   Mem[23] <- 3
macdm x30, x23, 21(x0)    # x30 = 6 + 3*2 = 12;  Mem[22] <- 2; acc x30 <- MEM/WB->MEM (forward_m)
macdm x30, x22, 20(x0)    # x30 = 12 + 4*1 = 16; Mem[21] <- 1; acc x30 <- MEM/WB->MEM (forward_m)

# 9. macdm in the shadow of a taken branch
beq   x0,  x0, DONE
macdm x21, x20, 24(x0)    # FLUSHED (x21 must stay 103, Mem[25] must stay 0)
macdm x21, x20, 24(x0)    # FLUSHED

DONE:
addi  x31, x0, 85         # x31 = 85

# =============================================================================
# Hazard summary
#   Accumulator (rd):
#     forward_m (MEM/WB->MEM, distance 1): ALU producer (1st macdm x21),
#       macdm producer (2nd macdm x21, 2nd and 3rd macdm x30), lw producer (macdm x24)
#     forward_c (MEM/WB->EX, distance 2): macdm x21, x23
#     3rd-port write-first bypass:        macdm x21, x22 (distance 3 after the stall)
#   Coefficient (rs2), existing forward_b paths:
#     MEM/WB: 1st macdm (x20); after the stall on macdm x21, x22; macdm x28, x1
#     EX/MEM: macdm x21, x23
#   Base (rs1), existing forward_a path:
#     EX/MEM: macdm x27, 2(x26)
#   Data move (in order with the other memory accesses, all in MEM):
#     macdm -> macdm reading A+8 (block 1), macdm -> lw of A+8 (block 4),
#     macdm -> sw to A+8 (block 6), sw to A -> macdm (block 7),
#     delay-line shift (block 8), no move from a flushed macdm (block 9)
#   Stalls (1 cycle each, HDU treats macdm as a load):
#     macdm x21, x22 (coefficient from lw x22)
#     add   x25      (consumes macdm x24)
#     sw    x27      (store data from macdm x27)
#   Flushes (taken branch, 2 instr each): beq x0,x0 -> two macdm
# =============================================================================
