div:
  PUSH FP
  SUB SP, 16
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
  MOV A, 3
  ADD B, FP, 8
  LD [B, 0], A ; quot
  MOV A, 4
  ADD B, FP, 8
  LD [B, 4], A ; rem
  ADD A, FP, 8
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
print_int:
  PUSH LR, B, C, D, E, FP
  SUB SP, 12
  MOV FP, SP
  LD [FP, 0], A
  LD C, [FP, 0] ; num
  MOV D, 10
  MOV A, C
  MOV B, D
  CALL div
  MOV C, A
  ADD D, FP, 4
  LD E, [C, 0]
  LD [D, 0], E
  LD E, [C, 4]
  LD [D, 4], E
  MOV SP, FP
  ADD SP, 12
  POP PC, B, C, D, E, FP