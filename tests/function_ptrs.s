.S0: "Cloud\0"
get_name:
  SUB    SP, 4
  ST     [SP, 0], A ; cat
  LD     A, [A, 0] ; .name
.L0:
  ADD    SP, 4
  RET
sqr:
  SUB    SP, 4
  ST     [SP, 0], A ; n
  MUL    A, A
.L1:
  ADD    SP, 4
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
  LD     A, [SP, 12] ; i
  LD     C, [SP, 4] ; f
  CALL   C
  ADD    A, B, A
  ST     [SP, 8], A ; s
.L4:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L3
.L5:
  LD     A, [SP, 8] ; s
.L2:
  ADD    SP, 16
  POP    C, PC
main:
  PUSH   B, LR
  SUB    SP, 20
  LDI    A, =.S0
  ST     [SP, 0], A ; cat.name
  MOV    A, 15
  ST     [SP, 4], A ; cat.age
  LDI    A, =get_name
  ST     [SP, 8], A ; cat.get_name
  ADD    A, SP, 0 ; cat
  LD     B, [SP, 8] ; cat.get_name
  CALL   B
  ST     [SP, 12], A ; name
  MOV    A, 10
  LDI    B, =sqr
  CALL   sum
  ST     [SP, 16], A ; n
  MOV    A, 0
.L6:
  ADD    SP, 20
  POP    B, PC