# 8-tap FIR filter, single output sample.
#
# y[n] = sum_{k=0}^{7} h[k] * x[n-k], for n = 7 (last sample of the window)
#
# Coefficients h[k] (triangular window, small integers on purpose -- this is
# a workload for comparing processor performance, not a filter meant for
# real signal processing):
#   h = {1, 2, 3, 4, 3, 2, 1, 1}
#
# Input samples x[i], i = 0..7, oldest first (x[7] is the current sample x[n],
# x[0] is the oldest, x[n-7]):
#   x = {1, 2, 3, 4, 5, 6, 7, 8}
#
# Expected result: y = 1*8 + 2*7 + 3*6 + 4*5 + 3*4 + 2*3 + 1*2 + 1*1
#                    = 8   + 14  + 18  + 20  + 12  + 6   + 2   + 1 = 81 (0x51)
#
# Data memory map (8-byte words):
#   h[0..7] at byte addresses   0, 8, 16, 24, 32, 40, 48, 56
#   x[0..7] at byte addresses  64, 72, 80, 88, 96, 104, 112, 120
#   y       at byte address   128

# ---- Load coefficients h[0..7] into memory ---------------------------------
addi x1, x0, 1
sw   x1, 0(x0)     # h[0] = 1
addi x1, x0, 2
sw   x1, 8(x0)     # h[1] = 2
addi x1, x0, 3
sw   x1, 16(x0)    # h[2] = 3
addi x1, x0, 4
sw   x1, 24(x0)    # h[3] = 4
addi x1, x0, 3
sw   x1, 32(x0)    # h[4] = 3
addi x1, x0, 2
sw   x1, 40(x0)    # h[5] = 2
addi x1, x0, 1
sw   x1, 48(x0)    # h[6] = 1
addi x1, x0, 1
sw   x1, 56(x0)    # h[7] = 1

# ---- Load input samples x[0..7] into memory ---------------------------------
addi x1, x0, 1
sw   x1, 64(x0)    # x[0] = 1
addi x1, x0, 2
sw   x1, 72(x0)    # x[1] = 2
addi x1, x0, 3
sw   x1, 80(x0)    # x[2] = 3
addi x1, x0, 4
sw   x1, 88(x0)    # x[3] = 4
addi x1, x0, 5
sw   x1, 96(x0)    # x[4] = 5
addi x1, x0, 6
sw   x1, 104(x0)   # x[5] = 6
addi x1, x0, 7
sw   x1, 112(x0)   # x[6] = 7
addi x1, x0, 8
sw   x1, 120(x0)   # x[7] = 8

# ---- MAC loop, sum accumulates in x31 ----------------------------
addi x31, x0, 0        # sum = 0

# tap k=0: h[0] * x[7]
lw   x2, 0(x0)          # h[0]
lw   x3, 120(x0)        # x[7]
mul  x4, x2, x3         # 1*8 = 8
add  x31, x31, x4       # sum = 8

# tap k=1: h[1] * x[6]
lw   x2, 8(x0)          # h[1]
lw   x3, 112(x0)        # x[6]
mul  x4, x2, x3         # 2*7 = 14
add  x31, x31, x4       # sum = 22

# tap k=2: h[2] * x[5]
lw   x2, 16(x0)         # h[2]
lw   x3, 104(x0)        # x[5]
mul  x4, x2, x3         # 3*6 = 18
add  x31, x31, x4       # sum = 40

# tap k=3: h[3] * x[4]
lw   x2, 24(x0)         # h[3]
lw   x3, 96(x0)         # x[4]
mul  x4, x2, x3         # 4*5 = 20
add  x31, x31, x4       # sum = 60

# tap k=4: h[4] * x[3]
lw   x2, 32(x0)         # h[4]
lw   x3, 88(x0)          # x[3]
mul  x4, x2, x3         # 3*4 = 12
add  x31, x31, x4       # sum = 72

# tap k=5: h[5] * x[2]
lw   x2, 40(x0)         # h[5]
lw   x3, 80(x0)         # x[2]
mul  x4, x2, x3         # 2*3 = 6
add  x31, x31, x4       # sum = 78

# tap k=6: h[6] * x[1]
lw   x2, 48(x0)         # h[6]
lw   x3, 72(x0)         # x[1]
mul  x4, x2, x3         # 1*2 = 2
add  x31, x31, x4       # sum = 80

# tap k=7: h[7] * x[0]
lw   x2, 56(x0)         # h[7]
lw   x3, 64(x0)         # x[0]
mul  x4, x2, x3         # 1*1 = 1
add  x31, x31, x4       # sum = 81

sw   x31, 128(x0)       # y = Mem[128] = 81 (0x51)