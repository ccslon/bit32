fact:
  PUSH LR, B, C, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 0
  JNE .L1
  MOV B, 1
  JMP .L0
.L1:
  LD B, [FP, 0] ; n
  LD C, [FP, 0] ; n
  SUB C, 1
  MOV A, C
  CALL fact
  MOV C, A
  MUL B, C
  JMP .L0
.L0:
  MOV A, B
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, FP