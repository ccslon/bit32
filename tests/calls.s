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
  MOV    A, -3
  MOV    B, 4
  CALL   bar
  ADD    A, C, A
.L2:
  ADD    SP, 12
  POP    PC
test:
  PUSH   D, E, LR
  SUB    SP, 24
  ST     [SP, 0], A ; a
  ST     [SP, 4], B ; b
  ST     [SP, 8], C ; c
  LD     D, [SP, 0] ; a
  LD     A, [SP, 4] ; b
  LD     B, [SP, 8] ; c
  ADD    B, D
  CALL   bar
  MOV    B, A
  LD     C, [SP, 8] ; c
  MOV    A, D
  CALL   foo
  ST     [SP, 12], A ; x
  LD     A, [SP, 0] ; a
  ADD    A, A
  MOV    B, 1
  CALL   bar
  LD     B, [SP, 4] ; b
  LD     C, [SP, 8] ; c
  CALL   foo
  ST     [SP, 16], A ; y
  LD     D, [SP, 0] ; a
  LD     E, [SP, 4] ; b
  MOV    A, 3
  ADD    B, SP, 8 ; c
  CALL   baz
  MOV    C, A
  MOV    A, D
  MOV    B, E
  CALL   foo
  ST     [SP, 20], A ; z
.L3:
  ADD    SP, 24
  POP    D, E, PC