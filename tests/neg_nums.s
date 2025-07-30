foo:
  PUSH   A
  SUB    SP, 12
  MVN    A, 3
  ADD    A, 4
  ST     [SP, 0], A ; n
  MOV    A, 3
  ADD    A, 4
  NEG    A
  ST     [SP, 4], A ; m
  MOV    A, 3
  ADD    A, -4
  NEG    A
  ST     [SP, 8], A ; o
  ADD    SP, 12
  POP    A
  RET