myfloat: .word 1069547520
foo:
  SUB SP, 8
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; a
  LD B, [SP, 4] ; b
  ADDF A, B
  JMP .L0
.L0:
  ADD SP, 8
  RET
func1:
  PUSH A, B, LR
  SUB SP, 4
  LDI A, 1069547520
  ST [SP, 0], A ; f
  LD A, [SP, 0] ; f
  LDI B, 3217031168
  CALL foo
  ADD SP, 4
  POP A, B, PC
half1:
  MOV A, 1
  DIV A, 2
  ITF A, A
  JMP .L1
.L1:
  RET
half2:
  PUSH B
  LDI A, 1065353216
  MOV B, 2
  ITF B, B
  DIVF A, B
  JMP .L2
.L2:
  POP B
  RET
half3:
  PUSH B
  MOV A, 1
  ITF A, A
  MOV B, 2
  ITF B, B
  DIVF A, B
  JMP .L3
.L3:
  POP B
  RET
func2:
  PUSH A, B
  SUB SP, 16
  LDI A, 1069547520
  FTI A, A
  ADD B, SP, 0
  ST [B, 4], A ; i
  ADD A, SP, 0
  LD A, [A, 0] ; f
  FTI A, A
  ST [SP, 8], A ; i
  ADD A, SP, 0
  LD A, [A, 4] ; i
  ITF A, A
  ADD B, SP, 0
  LD B, [B, 0] ; f
  ADDF A, B
  FTI A, A
  ST [SP, 12], A ; x
  ADD SP, 16
  POP A, B
  RET