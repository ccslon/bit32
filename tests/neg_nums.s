foo:
  PUSH A, B, FP
  SUB SP, 12
  MOV FP, SP
  MVN A, 3
  ADD A, 4
  LD [FP, 0], A ; n
  MOV A, 3
  ADD A, 4
  NEG A
  LD [FP, 4], A ; m
  MOV A, 3
  MVN B, 4
  ADD A, B
  NEG A
  LD [FP, 8], A ; o
  MOV SP, FP
  ADD SP, 12
  POP A, B, FP
  RET