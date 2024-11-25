foo: .word 9
test:
  PUSH A, FP
  SUB SP, 4
  MOV FP, SP
  MOV A, 10
  MUL A, 100
  ST [FP, 0], A ; num
  MOV SP, FP
  ADD SP, 4
  POP A, FP
  RET