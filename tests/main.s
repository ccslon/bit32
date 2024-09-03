main:
  PUSH FP
  MOV FP, SP
.L0:
  MOV SP, FP
  POP FP
  RET