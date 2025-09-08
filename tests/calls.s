baz:
  SUB    SP, 8
  ST     [SP, 0], A ; y
  ST     [SP, 4], B ; z
  LD     A, [SP, 0] ; y
  LD     B, [SP, 4] ; z
  LD     B, [B]
  MUL    A, B
.L0:
  ADD    SP, 8
  RET
bar:
  SUB    SP, 8
  ST     [SP, 0], A ; x
  ST     [SP, 4], B ; y
  LD     A, [SP, 0] ; x
  LD     B, [SP, 4] ; y
  MUL    A, B
.L1:
  ADD    SP, 8
  RET
foo:
  PUSH   LR
  SUB    SP, 12
  ST     [SP, 0], A ; x
  ST     [SP, 4], B ; y
  ST     [SP, 8], C ; z
  LD     A, [SP, 0] ; x
  LD     B, [SP, 4] ; y
  CALL   bar
  MOV    C, A
  LD     A, [SP, 4] ; y
  ADD    B, SP, 8 ; z
  CALL   baz
  ADD    C, A
  MVN    A, 3
  MOV    B, 4
  CALL   bar
  ADD    C, A
.L2:
  MOV    A, C
  ADD    SP, 12
  POP    PC