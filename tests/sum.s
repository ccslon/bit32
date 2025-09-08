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
  LD     A, [SP, 12] ; i
  LD     C, [SP, 4] ; f
  LD     D, [SP, 12] ; i
  SHL    D, 2
  LD     C, [C, D]
  CALL   C
  ADD    B, A
  ST     [SP, 8], B ; s
.L2:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L1
.L3:
  LD     B, [SP, 8] ; s
.L0:
  MOV    A, B
  ADD    SP, 16
  POP    C, D, PC
sqr:
  PUSH   B
  SUB    SP, 4
  ST     [SP, 0], A ; n
  LD     A, [SP, 0] ; n
  LD     B, [SP, 0] ; n
  MUL    A, B
.L4:
  ADD    SP, 4
  POP    B
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
  ADD    B, A
  ST     [SP, 8], B ; sum
.L7:
  LD     A, [SP, 12] ; i
  ADD    B, A, 1
  ST     [SP, 12], B ; i
  JMP    .L6
.L8:
  LD     B, [SP, 8] ; sum
.L5:
  MOV    A, B
  ADD    SP, 16
  POP    C, PC
main:
  PUSH   B, C, D, LR
  SUB    SP, 20
  ADD    C, SP, 0 ; funcs
  LDI    D, =sqr
  ST     [C, 0], D
  LDI    D, =sqr
  ST     [C, 4], D
  LDI    D, =sqr
  ST     [C, 8], D
  LDI    D, =sqr
  ST     [C, 12], D
  MOV    A, 4
  ADD    B, SP, 0 ; funcs
  CALL   sumfs
  ST     [SP, 16], A ; result
  MOV    A, 5
  LDI    B, =sqr
  CALL   sum
  MOV    C, A
.L9:
  MOV    A, C
  ADD    SP, 20
  POP    B, C, D, PC