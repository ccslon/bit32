myfloat: .word 1069547520
foo:
  SUB    SP, 8
  ST     [SP, 0], A ; a
  ST     [SP, 4], B ; b
  LD     A, [SP, 0] ; a
  LD     B, [SP, 4] ; b
  ADDF   A, B
  JMP    .L0
.L0:
  ADD    SP, 8
  RET
func1:
  PUSH   A, B, LR
  SUB    SP, 4
  LDI    A, 1069547520
  ST     [SP, 0], A ; f
  LD     A, [SP, 0] ; f
  LDI    B, 3217031168
  CALL   foo
  ADD    SP, 4
  POP    A, B, PC
half1:
  MOV    A, 1
  DIV    A, 2
  ITF    A, A
  JMP    .L1
.L1:
  RET
half2:
  PUSH   B
  LDI    A, 1065353216
  ITF    B, 2
  DIVF   A, B
  JMP    .L2
.L2:
  POP    B
  RET
half3:
  PUSH   B
  ITF    A, 1
  ITF    B, 2
  DIVF   A, B
  JMP    .L3
.L3:
  POP    B
  RET
func2:
  PUSH   A, B
  SUB    SP, 16
  LDI    A, 1069547520
  FTI    A, A
  ST     [SP, 4], A ; foo
  LD     A, [SP, 0] ; foo
  FTI    A, A
  ST     [SP, 8], A ; i
  LD     A, [SP, 4] ; foo
  ITF    A, A
  LD     B, [SP, 0] ; foo
  ADDF   A, B
  FTI    A, A
  ST     [SP, 12], A ; x
  ADD    SP, 16
  POP    A, B
  RET