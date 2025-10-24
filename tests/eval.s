f: .word 1107296256
g: .word 32
half: .word 1056964608
.S0: "def\0"
main:
  SUB    SP, 52
  MOV    A, 128
  ST     [SP, 0], A ; i
  LDI    A, 1124073472 ; 128.0
  ST     [SP, 4], A ; j
  LDI    A, 3204448256 ; -0.5
  ST     [SP, 8], A ; k
  MOV    A, 4
  ST     [SP, 12], A ; l
  LD     A, [SP, 12] ; l
  ADD    A, 3
  ST     [SP, 16], A ; m
  MOV    A, 0
  ST     [SP, 20], A ; n
  MOV    A, 1
  ST     [SP, 24], A ; m
  MOV    A, 1
  ST     [SP, 28], A ; o
  LD     A, [SP, 24] ; m
  ST     [SP, 32], A ; p
  MOV    A, 4
  ST     [SP, 36], A ; q
  LDI    A, =.S0
  ST     [SP, 40], A ; r
  MOV    A, 2
  ST     [SP, 44], A ; s
  MOV    A, 5
  ST     [SP, 48], A ; t
.L0:
  ADD    SP, 52
  RET
test_loops:
  PUSH   A, B, LR
  SUB    SP, 12
.L1:
  CALL   foo
  JMP    .L1
.L2:
.L3:
  JMP    .L4
  CALL   foo
  JMP    .L3
.L4:
  MOV    A, 0
  ST     [SP, 0], A ; i
.L5:
  LD     A, [SP, 8] ; q
  ADD    B, A, 1
  ST     [SP, 8], B ; q
  ST     [SP, 4], A ; p
  CALL   foo
.L6:
  LD     A, [SP, 0] ; i
  ADD    B, A, 1
  ST     [SP, 0], B ; i
  JMP    .L5
.L7:
.L8:
  CALL   foo
.L9:
  ADD    SP, 12
  POP    A, B, PC
test_ifs:
  PUSH   A, B, LR
  SUB    SP, 4
  JMP    .L11
  CALL   foo
  JMP    .L10
.L11:
  LD     A, [SP, 0] ; q
  ADD    B, A, 1
  ST     [SP, 0], B ; q
  JMP    .L10
.L12:
  MOV    A, 10
  ST     [SP, 0], A ; q
.L10:
  ADD    SP, 4
  POP    A, B, PC