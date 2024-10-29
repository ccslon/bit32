main:
  PUSH FP
  SUB SP, 5
  MOV FP, SP
  MOV A, 10
  ST.B [FP, 0], A ; day
  MOV A, 4
  ST [FP, 1], A ; today
  MOV A, 0
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 5
  POP FP
  RET