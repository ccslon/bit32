sumfs:
  PUSH   C, D, LR
  SUB    SP, 16
  ST     [SP, 0], A ; n
  ST     [SP, 4], B ; f
  MOV    A, 0
  ST     [SP, 8], A ; s
  MOV    A, 0
  ST     [SP, 12], A ; i
.L1:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 0] ; n
  CMP    A, B
  JGE    .L3
  LD     B, [SP, 8] ; s
  LD     D, [SP, 12] ; i
  MOV    A, D
  LD     C, [SP, 4] ; f
  SHL    D, 2
  LD     C, [C, D]
  CALL   C
  ADD    A, B, A
  ST     [SP, 8], A ; s
.L2:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L1
.L3:
  LD     A, [SP, 8] ; s
.L0:
  ADD    SP, 16
  POP    C, D, PC
sqr:
  SUB    SP, 4
  ST     [SP, 0], A ; n
  MUL    A, A
.L4:
  ADD    SP, 4
  RET
sum:
  PUSH   C, LR
  SUB    SP, 16
  ST     [SP, 0], A ; n
  ST     [SP, 4], B ; f
  MOV    A, 0
  ST     [SP, 8], A ; sum
  MOV    A, 0
  ST     [SP, 12], A ; i
.L6:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 0] ; n
  CMP    A, B
  JGE    .L8
  LD     B, [SP, 8] ; sum
  LD     A, [SP, 12] ; i
  LD     C, [SP, 4] ; f
  CALL   C
  ADD    A, B, A
  ST     [SP, 8], A ; sum
.L7:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L6
.L8:
  LD     A, [SP, 8] ; sum
.L5:
  ADD    SP, 16
  POP    C, PC
main:
  PUSH   B, LR
  SUB    SP, 20
  ADD    A, SP, 0 ; funcs
  LDI    B, =sqr
  ST     [A, 0], B
  LDI    B, =sqr
  ST     [A, 4], B
  LDI    B, =sqr
  ST     [A, 8], B
  LDI    B, =sqr
  ST     [A, 12], B
  MOV    A, 4
  ADD    B, SP, 0 ; funcs
  CALL   sumfs
  ST     [SP, 16], A ; result
  MOV    A, 5
  LDI    B, =sqr
  CALL   sum
.L9:
  ADD    SP, 20
  POP    B, PC