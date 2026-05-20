foo:
  PUSH   A, B
  SUB    SP, 20
  MOV    A, -4
  ST     [SP, 0], A ; i
  LDI    A, 4294966296
  ST     [SP, 4], A ; j
  MOV    A, 1
  ST     [SP, 8], A ; n
  MOV    B, -7
  ST     [SP, 12], B ; m
  ST     [SP, 16], A ; o
  ADD    SP, 20
  POP    A, B
  RET