data:
  .half 1234
  .half 650
  .half 333
  .half 6262
  .half 563
ptr: .space 4
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
  MOV    B, 10
  DIV    B, 2
  CMP    A, B
  JGE    .L2
  LD     A, [SP, 4] ; s
  LDI    B, =data
  LD     C, [SP, 0] ; i
  MUL    C, 2
  LD.H   B, [B, C]
  ADD    A, B
  ST     [SP, 4], A ; s
.L1:
  LD     A, [SP, 0] ; i
  ADD    B, A, 1
  ST     [SP, 0], B ; i
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
  MOV    B, 10
  DIV    B, 2
  CMP    A, B
  JGE    .L5
  LD     A, [SP, 4] ; s
  LDI    B, =data
  LD     C, [SP, 0] ; i
  MUL    C, 2
  LD.H   B, [B, C]
  ADD    A, B
  ST     [SP, 4], A ; s
.L4:
  LD     A, [SP, 0] ; i
  ADD    B, A, 1
  ST     [SP, 0], B ; i
  JMP    .L3
.L5:
  ADD    SP, 8
  POP    A, B, C
  RET