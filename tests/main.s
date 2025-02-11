main:
  PUSH FP
  MOV FP, SP
  MOV A, 0
  JMP .L0
.L0:
  MOV SP, FP
  POP FP
  RET