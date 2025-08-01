.S0: "Cloud\0"
get_name:
  SUB    SP, 4
  ST     [SP, 0], A ; cat
  LD     A, [SP, 0] ; cat
  LD     A, [A, 0] ; .name
.L0:
  ADD    SP, 4
  RET
sqr:
  PUSH   B
  SUB    SP, 4
  ST     [SP, 0], A ; n
  LD     A, [SP, 0] ; n
  LD     B, [SP, 0] ; n
  MUL    A, B
.L1:
  ADD    SP, 4
  POP    B
  RET
sum:
  PUSH   C, LR
  SUB    SP, 16
  ST     [SP, 0], A ; n
  ST     [SP, 4], B ; f
  MOV    A, 0
  ST     [SP, 8], A ; s
  MOV    A, 0
  ST     [SP, 12], A ; i
.L3:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 0] ; n
  CMP    A, B
  JGE    .L5
  LD     B, [SP, 8] ; s
  LD     C, [SP, 12] ; i
  MOV    A, C
  LD     C, [SP, 4] ; f
  CALL   C
  ADD    B, A
  ST     [SP, 8], B ; s
.L4:
  LD     A, [SP, 12] ; i
  ADD    B, A, 1
  ST     [SP, 12], B ; i
  JMP    .L3
.L5:
  LD     B, [SP, 8] ; s
.L2:
  MOV    A, B
  ADD    SP, 16
  POP    C, PC
main:
  PUSH   B, C, LR
  SUB    SP, 20
  LDI    A, =.S0
  ST     [SP, 0], A ; cat
  MOV    A, 15
  ST     [SP, 4], A ; cat
  LDI    A, =get_name
  ST     [SP, 8], A ; cat
  ADD    A, SP, 0 ; cat
  LD     B, [SP, 8] ; cat
  CALL   B
  ST     [SP, 12], A ; name
  MOV    A, 10
  LDI    B, =sqr
  CALL   sum
  ST     [SP, 16], A ; n
  MOV    C, 0
.L6:
  MOV    A, C
  ADD    SP, 20
  POP    B, C, PC