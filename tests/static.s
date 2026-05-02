n: .word 3
next_int_n: .word 0
f: .word 0
next_int:
  PUSH   B, C
  LDI    A, =next_int_n
  LD     A, [A]
  ADD    B, A, 1
  LDI    C, =next_int_n
  ST     [C], B
.L0:
  POP    B, C
  RET
main:
  LDI    A, =n
  LD     A, [A]
  CMP    A, 10
  JLE    .L2
  LDI    A, =n
  LD     A, [A]
  JMP    .L1
.L2:
  MOV    A, 0
.L1:
  RET