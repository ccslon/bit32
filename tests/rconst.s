func:
  PUSH A, B, FP
  SUB SP, 16
  MOV FP, SP
  MOV A, 3
  ST [FP, 0], A ; i1
  MOV A, 2
  LD B, [FP, 0] ; i1
  SUB A, B
  ST [FP, 4], A ; i2
  LDI A, 1069547520
  ST [FP, 8], A ; f1
  MOV A, 1
  ITF A, A
  LD B, [FP, 8] ; f1
  SUBF A, B
  ST [FP, 12], A ; f2
  MOV SP, FP
  ADD SP, 16
  POP A, B, FP
  RET