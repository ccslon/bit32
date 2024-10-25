func:
  PUSH A, FP
  SUB SP, 12
  MOV FP, SP
  LDI A, 805306368
  ST [FP, 0], A ; i
  LDI A, 300
  ST.H [FP, 4], A ; s
  MOV A, 3
  ST.B [FP, 6], A ; c
  MOV.B A, 'c'
  ST.B [FP, 7], A ; l
  LDI A, 1069547520
  ST [FP, 8], A ; f
  MOV SP, FP
  ADD SP, 12
  POP A, FP
  RET