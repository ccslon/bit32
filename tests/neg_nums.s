foo:
  PUSH A, FP
  SUB SP, 12
  MOV FP, SP
  MVN A, 3
  ADD A, 4
  ST [FP, 0], A ; n
  MOV A, 3
  ADD A, 4
  NEG A
  ST [FP, 4], A ; m
  MOV A, 3
  ADD A, -4
  NEG A
  ST [FP, 8], A ; o
  MOV SP, FP
  ADD SP, 12
  POP A, FP
  RET