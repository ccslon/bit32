foo1:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 1
  JNE .L0
  MOV B, 100
  MOV A, B
  CALL bar
.L0:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
foo2:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 1
  JNE .L2
  MOV B, 100
  MOV A, B
  CALL bar
  JMP .L1
.L2:
  LD B, [FP, 0] ; n
  CMP B, 100
  JLE .L1
  MVN B, 1
  MOV A, B
  CALL bar
.L1:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
foo2_5:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 1
  JNE .L4
  MOV B, 100
  MOV A, B
  CALL bar
  JMP .L3
.L4:
  LD B, [FP, 0] ; n
  CMP B, 100
  JLE .L5
  MVN B, 1
  MOV A, B
  CALL bar
.L5:
.L3:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
foo3:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 1
  JNE .L7
  MOV B, 100
  MOV A, B
  CALL bar
  JMP .L6
.L7:
  MOV B, 0
  MOV A, B
  CALL bar
.L6:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
foo4:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 1
  JNE .L9
  MOV B, 100
  MOV A, B
  CALL bar
  JMP .L8
.L9:
  LD B, [FP, 0] ; n
  CMP B, 100
  JLE .L10
  MVN B, 1
  MOV A, B
  CALL bar
  JMP .L8
.L10:
  MOV B, 0
  MOV A, B
  CALL bar
.L8:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
main:
  PUSH FP
  MOV FP, SP
.L11:
  MOV SP, FP
  POP FP
  RET