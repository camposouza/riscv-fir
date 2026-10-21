# 8-tap FIR filter on the macdm core, 16 input samples -> 23 outputs
# (full convolution: 7 fill + 9 steady-state + 7 drain).
#
# macdm rd, rs2, off(rs1)  ->  rd <= rd + rs2 * Mem[A],  Mem[A+8] <= Mem[A],
#                              A = rs1 + off*8 (off = word offset, in funct7)
#
# Coefficients
#   h = {1, 2, 3, 4, 4, 3, 2, 1}
#
# Input samples:
#   x = {4, 11, 17, 17, 4, 8, 20, 20, 18, 14, 19, 18, 16, 19, 15, 8}
#
# Expected outputs:
#   y = {4, 19, 51, 100, 149, 191, 225, 245, 262, 285, 310, 330, 345, 351, 347, 334,
#        307, 263, 199, 131, 73, 31, 8}
#
# Delay line d[0-7]: d[k] holds x[n-k] while y[n] is computed (d[0] = newest). It starts zeroed.
# Each tap is one macdm: it accumulates h[k] * d[k] and, in the same instruction,
# stores d[k] one position ahead (d[k+1] = d[k]).
# Taps run from the oldest (k = 7) to the newest (k = 0), so every store lands on a position
# already consumed. d[8] is a discard slot, written by tap 7 and never read.
#
# After the 16 real inputs, the loop runs 7 more times feeding x[16-22] = 0
# (memory reset value, no setup store needed), which drains the delay line.
#
# Data memory map (8-byte words, byte addresses):
#   h[0-7]   0 .. 56
#   x[0-22]  64 .. 240   (x[16-22] = 0)
#   d[0-8]   248 .. 312  (word offsets 31 .. 39)
#   y[0-22]  320 .. 496
#
# Registers:
#   x1        setup temporary
#   x2        &x[n]          (input pointer)
#   x3        &y[n]          (output pointer)
#   x4        &x[23] = 248   (loop end)
#   x5        sample
#   x7        accumulator
#   x10..x17  h[0-7]

# ---- Setup (not measured): coefficients h[0-7] into memory ---------------
addi x1, x0, 1
sw   x1, 0(x0)          # h[0] = 1
addi x1, x0, 2
sw   x1, 8(x0)          # h[1] = 2
addi x1, x0, 3
sw   x1, 16(x0)         # h[2] = 3
addi x1, x0, 4
sw   x1, 24(x0)         # h[3] = 4
addi x1, x0, 4
sw   x1, 32(x0)         # h[4] = 4
addi x1, x0, 3
sw   x1, 40(x0)         # h[5] = 3
addi x1, x0, 2
sw   x1, 48(x0)         # h[6] = 2
addi x1, x0, 1
sw   x1, 56(x0)         # h[7] = 1

# ---- Setup (not measured): input samples x[0-15] into memory -------------
addi x1, x0, 4
sw   x1, 64(x0)         # x[0]  = 4
addi x1, x0, 11
sw   x1, 72(x0)         # x[1]  = 11
addi x1, x0, 17
sw   x1, 80(x0)         # x[2]  = 17
addi x1, x0, 17
sw   x1, 88(x0)         # x[3]  = 17
addi x1, x0, 4
sw   x1, 96(x0)         # x[4]  = 4
addi x1, x0, 8
sw   x1, 104(x0)        # x[5]  = 8
addi x1, x0, 20
sw   x1, 112(x0)        # x[6]  = 20
addi x1, x0, 20
sw   x1, 120(x0)        # x[7]  = 20
addi x1, x0, 18
sw   x1, 128(x0)        # x[8]  = 18
addi x1, x0, 14
sw   x1, 136(x0)        # x[9]  = 14
addi x1, x0, 19
sw   x1, 144(x0)        # x[10] = 19
addi x1, x0, 18
sw   x1, 152(x0)        # x[11] = 18
addi x1, x0, 16
sw   x1, 160(x0)        # x[12] = 16
addi x1, x0, 19
sw   x1, 168(x0)        # x[13] = 19
addi x1, x0, 15
sw   x1, 176(x0)        # x[14] = 15
addi x1, x0, 8
sw   x1, 184(x0)        # x[15] = 8

# ---- Filter (measured) ----------------------------------------------------
# Coefficients into registers
lw   x10, 0(x0)         # h[0]
lw   x11, 8(x0)         # h[1]
lw   x12, 16(x0)        # h[2]
lw   x13, 24(x0)        # h[3]
lw   x14, 32(x0)        # h[4]
lw   x15, 40(x0)        # h[5]
lw   x16, 48(x0)        # h[6]
lw   x17, 56(x0)        # h[7]

# Pointers
addi x2, x0, 64         # x2 = &x[0]
addi x3, x0, 320        # x3 = &y[0]
addi x4, x0, 248        # x4 = &x[23] (end)

# One output sample y[n] per iteration
loop:
lw   x5, 0(x2)          # x5 = x[n]
addi x7, x0, 0          # acc = 0
sw   x5, 248(x0)        # d[0] = x[n]

# taps 7..0: acc += h[k] * d[k];  d[k+1] = d[k]
macdm x7, x17, 38(x0)   # tap 7: d[7], d[8] = d[7]
macdm x7, x16, 37(x0)   # tap 6: d[6], d[7] = d[6]
macdm x7, x15, 36(x0)   # tap 5: d[5], d[6] = d[5]
macdm x7, x14, 35(x0)   # tap 4: d[4], d[5] = d[4]
macdm x7, x13, 34(x0)   # tap 3: d[3], d[4] = d[3]
macdm x7, x12, 33(x0)   # tap 2: d[2], d[3] = d[2]
macdm x7, x11, 32(x0)   # tap 1: d[1], d[2] = d[1]
macdm x7, x10, 31(x0)   # tap 0: d[0], d[1] = d[0]

sw   x7, 0(x3)          # y[n] = acc
addi x2, x2, 8          # n++
addi x3, x3, 8
bne  x2, x4, loop       # x[n] = x[23] ?
