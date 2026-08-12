# ALU Operations and forwarding
addi x1,  x0, 10          # x1 = 10
addi x2,  x0, 3           # x2 = 3
add  x3,  x1, x2          # x3 = 13
sub  x4,  x3, x2          # x4 = 10 (forwarding de x3)
and  x5,  x4, x1          # x5 = 10 (forwarding de x4)
or   x6,  x5, x2          # x6 = 11 (forwarding de x5)

# Store, load and hazard load-use: must insert 1 stall
sw   x6,  0(x0)           # Mem[0] = 11
lw   x7,  0(x0)           # x7 = 11
addi x8,  x7, 1           # x8 = 12; depende do lw imediatamente anterior
add  x9,  x8, x7          # x9 = 23

# Branch taken: x10 e x11 must continue zero
beq  x9,  x9, TAKEN_1
addi x10, x0, 111         # must flush
addi x11, x0, 222         # must flush

TAKEN_1:
# Branch not taken: x12 must execute
beq  x9,  x8, AFTER_NOT_TAKEN
addi x12, x0, 7           # x12 = 7

AFTER_NOT_TAKEN:
addi x13, x0, 16          # x13 = 16
sw   x13, 8(x0)           # Mem[8] = 16
lw   x14, 8(x0)           # x14 = 16

# Branch depends at a lw: must insert 1 stall and then forward x14
beq  x14, x13, TAKEN_2
addi x16, x0, 1           # deve sofrer flush
addi x17, x0, 1           # deve sofrer flush

TAKEN_2:
add  x15, x14, x1         # x15 = 26

# Branch dependent on the immediately preceding ALU operation: forwarding to the branch
beq  x15, x15, PASS
addi x18, x0, 1           # must flush
addi x19, x0, 1           # must flush

PASS:
addi x31, x0, 85