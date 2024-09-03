func:
  PUSH A, B, FP
  SUB SP, 16
  MOV FP, SP
  MOV A, 3
  LD [FP, 0], A ; i1
  MOV A, 2
  LD B, [FP, 0] ; i1
  SUB A, B
  LD [FP, 4], A ; i2
  LD A, 1069547520
  LD [FP, 8], A ; f1
  MOV A, 1
  ITF A, A
  LD B, [FP, 8] ; f1
  SUBF A, B
  LD [FP, 12], A ; f2
  MOV SP, FP
  ADD SP, 16
  POP A, B, FP
  RET