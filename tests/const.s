func1:
  PUSH A, FP
  SUB SP, 12
  MOV FP, SP
  LD A, 805306368
  LD [FP, 0], A ; i
  LD A, 300
  LD.H [FP, 4], A ; s
  MOV A, 3
  LD.B [FP, 6], A ; c
  MOV.B A, 'c'
  LD.B [FP, 7], A ; l
  LD A, 1069547520
  LD [FP, 8], A ; f
  MOV SP, FP
  ADD SP, 12
  POP A, FP
  RET