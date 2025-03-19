func:
  PUSH A
  SUB SP, 12
  LDI A, 805306368
  ST [SP, 0], A ; i
  LDI A, 300
  ST.H [SP, 4], A ; s
  MOV A, 3
  ST.B [SP, 6], A ; c
  MOV.B A, 'c'
  ST.B [SP, 7], A ; l
  LDI A, 1069547520
  ST [SP, 8], A ; f
  ADD SP, 12
  POP A
  RET