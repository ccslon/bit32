data:
  .half 1234
  .half 650
  .half 333
  .half 6262
  .half 563
ptr: .word 0
num: .half 6
foo:
  PUSH   A, LR
  SUB    SP, 4
  MOV    A, 7
  CALL   alloc
  ST     [SP, 0], A ; thing
  ADD    SP, 4
  POP    A, PC
loop1:
  PUSH   A, B, C
  SUB    SP, 8
  MOV    A, 0
  ST     [SP, 4], A ; s
  MOV    A, 0
  ST     [SP, 0], A ; i
.L0:
  LD     A, [SP, 0] ; i
  CMP    A, 5
  JGE    .L2
  LD     C, [SP, 4] ; s
  LDI    B, =data
  LD     A, [SP, 0] ; i
  SHL    A, 1
  LD.H   A, [B, A]
  ADD    A, C, A
  ST     [SP, 4], A ; s
.L1:
  LD     A, [SP, 0] ; i
  ADD    A, 1
  ST     [SP, 0], A ; i
  JMP    .L0
.L2:
  ADD    SP, 8
  POP    A, B, C
  RET
loop2:
  PUSH   A, B, C
  SUB    SP, 8
  MOV    A, 0
  ST     [SP, 4], A ; s
  MOV    A, 0
  ST     [SP, 0], A ; i
.L3:
  LD     A, [SP, 0] ; i
  CMP    A, 5
  JGE    .L5
  LD     C, [SP, 4] ; s
  LDI    B, =data
  LD     A, [SP, 0] ; i
  SHL    A, 1
  LD.H   A, [B, A]
  ADD    A, C, A
  ST     [SP, 4], A ; s
.L4:
  LD     A, [SP, 0] ; i
  ADD    A, 1
  ST     [SP, 0], A ; i
  JMP    .L3
.L5:
  ADD    SP, 8
  POP    A, B, C
  RET