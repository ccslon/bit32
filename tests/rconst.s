func:
  PUSH   A, B
  SUB    SP, 16
  MOV    A, 3
  ST     [SP, 0], A ; i1
  MOV    A, 2
  LD     B, [SP, 0] ; i1
  SUB    A, B
  ST     [SP, 4], A ; i2
  LDI    A, 1069547520 ; 1.5
  ST     [SP, 8], A ; f1
  ITF    A, 1
  LD     B, [SP, 8] ; f1
  SUBF   A, B
  ST     [SP, 12], A ; f2
  ADD    SP, 16
  POP    A, B
  RET