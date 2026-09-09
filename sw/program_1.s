# ALU Operations and forwarding
addi x1,  x0, 10          # x1 = 10
addi x2,  x0, 3           # x2 = 3
add  x3,  x1, x2          # x3 = 13; FWD x2 <- EX/MEM; FWD x1 <- MEM/WB
sub  x4,  x3, x2          # x4 = 10; FWD x3 <- EX/MEM; FWD x2 <- MEM/WB
and  x5,  x4, x1          # x5 = 10; FWD x4 <- EX/MEM
or   x6,  x5, x2          # x6 = 11; FWD x5 <- EX/MEM

# Store, load and hazard load-use
sw   x6,  0(x0)           # Mem[0] = 11; FWD x6 <- EX/MEM
lw   x7,  0(x0)           # x7 = 11
addi x8,  x7, 1           # x8 = 12; STALL 1 cycle, then FWD x7 <- MEM/WB
add  x9,  x8, x7          # x9 = 23; FWD x8 <- EX/MEM

# Branch taken and flush
beq  x9,  x9, TAKEN_1     # FWD x9 <- EX/MEM on BOTH operands
addi x10, x0, 111         # FLUSHED
addi x11, x0, 222         # FLUSHED

TAKEN_1:
# Branch not taken
beq  x9,  x8, NOT_TAKEN
addi x12, x0, 7           # x12 = 7
NOT_TAKEN:
addi x13, x0, 16          # x13 = 16
sw   x13, 8(x0)           # Mem[8] = 16; FWD x13 <- EX/MEM
lw   x14, 8(x0)           # x14 = 16

# Branch depends at a lw and flush
beq  x14, x13, TAKEN_2    # STALL 1 cycle, then FWD x14 <- MEM/WB
addi x16, x0, 1           # x16 = 1; FLUSHED
addi x17, x0, 1           # x17 = 1; FLUSHED
TAKEN_2:
add  x15, x14, x1         # x15 = 26

# Branch dependent on the ALU operation and flush
beq  x15, x15, PASS       # FWD x15 <- EX/MEM on BOTH operands
addi x18, x0, 1           # x18 = 1; FLUSHED
addi x19, x0, 1           # x19 = 1; FLUSHED

PASS:
addi x31, x0, 85          # x31 = 85

# =============================================================================
# Hazard summary
#   Forwardings (EX/MEM->EX unless noted):
#     add  x3  : x2 (EX/MEM), x1 (MEM/WB)
#     sub  x4  : x3 (EX/MEM), x2 (MEM/WB)
#     and  x5  : x4 (EX/MEM)
#     or   x6  : x5 (EX/MEM)
#     sw   x6  : x6 (EX/MEM, store data)
#     addi x8  : x7 (MEM/WB, after the load-use stall)
#     add  x9  : x8 (EX/MEM); x7 via register-file write-first bypass
#     beq  x9,x9 : x9 on both operands (EX/MEM)
#     sw   x13 : x13 (EX/MEM, store data)
#     beq  x14,x13 : x14 (MEM/WB, after the load-use stall)
#     beq  x15,x15 : x15 on both operands (EX/MEM)
#   Stalls (load-use, 1 cycle each): addi x8 (after lw x7), beq x14 (after lw x14)
#   Flushes (taken branch, 2 instr each):
#     beq x9,x9  -> addi x10, addi x11
#     beq x14,x13 -> addi x16, addi x17
#     beq x15,x15 -> addi x18, addi x19
#   Correctly predicted not-taken (no penalty): beq x9,x8
# =============================================================================
