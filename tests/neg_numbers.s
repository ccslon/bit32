foo:
  PUSH   A
  SUB    SP, 20
  MOV    A, -4
  ST     [SP, 0], A ; i
  LDI    A, 4294966296
  ST     [SP, 4], A ; j
  MOV    A, 1
  ST     [SP, 8], A ; n
  MOV    A, -7
  ST     [SP, 12], A ; m
  MOV    A, 1
  ST     [SP, 16], A ; o
  ADD    SP, 20
  POP    A
  RET