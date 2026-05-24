main:
  PUSH   B, C, D, E
  SUB    SP, 16
  LD     A, [SP, 0] ; a
  ADD    A, A
  ST     [SP, 4], A ; b
  LD     A, [SP, 0] ; a
  LD     B, [SP, 4] ; b
  ADD    A, B
  MUL    A, A
  ST     [SP, 8], A ; c
  MOV.B  A, 'c'
  LD     C, [SP, 12] ; buf
  LD     B, [C, 0] ; .data
  LD     C, [C, 8] ; .write
  ST.B   [B, C], A
  MOV.B  A, '!'
  LD     B, [SP, 12] ; buf
  LD     C, [B, 0] ; .data
  LD     D, [B, 8] ; .write
  ADD    E, D, 1
  ST     [B, 8], E ; .write
  ST.B   [C, D], A
.L0:
  ADD    SP, 16
  POP    B, C, D, E
  RET
foo:
  PUSH   B, C
  SUB    SP, 60
  ADD    A, SP, 20 ; a
  LD     B, [SP, 12] ; i
  SHL    B, 2
  LD     A, [A, B]
  ST     [SP, 0], A ; x
  LD     A, [SP, 4] ; y
  ADD    B, SP, 20 ; a
  LD     C, [SP, 16] ; j
  SHL    C, 2
  ST     [B, C], A
  ADD    A, SP, 20 ; a
  LD     B, [SP, 12] ; i
  SHL    B, 2
  LD     A, [A, B]
  ST     [SP, 8], A ; z
.L1:
  ADD    SP, 60
  POP    B, C
  RET