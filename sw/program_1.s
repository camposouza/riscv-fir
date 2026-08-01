addi x1, x0, 10      # x1 = 10
addi x2, x0, 20      # x2 = 20
add  x3, x1, x2      # x3 = x1 + x2 = 30
sw   x3, 0(x0)       # Mem[0] = 30
lw   x4, 0(x0)       # x4 = Mem[0] = 30
beq  x3, x4, OK      # if x3 == x4 go to OK
addi x5, x0, 1       # NOT EXECUTED
OK:
addi x6, x0, 42      # x6 = 42
