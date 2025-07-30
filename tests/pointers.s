change:
  PUSH   B
  SUB    SP, 4
  ST     [SP, 0], A ; n
  LD     A, [SP, 0] ; n
  LD     A, [A]
  ADD    A, 10
  LD     B, [SP, 0] ; n
  ST     [B], A
  ADD    SP, 4
  POP    B
  RET
foo:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; m
  LD     A, [SP, 0] ; m
  MUL    A, 5
  ST     [SP, 4], A ; n
  ADD    A, SP, 4 ; n
  CALL   change
  ADD    SP, 8
  POP    PC
bar:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; str
  ST     [SP, 4], B ; i
  LD     A, [SP, 0] ; str
  CALL   print
  LD     A, [SP, 0] ; str
  LD     B, [SP, 4] ; i
  ADD    A, B
  CALL   print
  ADD    SP, 8
  POP    PC