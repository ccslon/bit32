params0:
  MOV    A, 0
.L0:
  RET
params1:
  SUB    SP, 4
  ST     [SP, 0], A ; foo
.L1:
  ADD    SP, 4
  RET
params2:
  SUB    SP, 8
  ST     [SP, 0], A ; foo
  ST     [SP, 4], B ; bar
  LD     A, [SP, 0] ; foo
  LD     B, [SP, 4] ; bar
  ADD    A, B
.L2:
  ADD    SP, 8
  RET
params3:
  SUB    SP, 12
  ST     [SP, 0], A ; foo
  ST     [SP, 4], B ; bar
  ST     [SP, 8], C ; baz
  LD     A, [SP, 0] ; foo
  LD     B, [SP, 4] ; bar
  ADD    A, B
  LD     B, [SP, 8] ; baz
  ADD    A, B
.L3:
  ADD    SP, 12
  RET
params4:
  SUB    SP, 16
  ST     [SP, 0], A ; foo
  ST     [SP, 4], B ; bar
  ST     [SP, 8], C ; baz
  ST     [SP, 12], D ; bif
  LD     A, [SP, 0] ; foo
  LD     B, [SP, 4] ; bar
  ADD    A, B
  LD     B, [SP, 8] ; baz
  ADD    A, B
  LD     B, [SP, 12] ; bif
  ADD    A, B
.L4:
  ADD    SP, 16
  RET
params5:
  SUB    SP, 20
  ST     [SP, 0], A ; a
  ST     [SP, 4], B ; b
  ST     [SP, 8], C ; c
  ST     [SP, 12], D ; d
  MOV    A, 10
  ST     [SP, 16], A ; i
  LD     C, [SP, 0] ; a
  LD     A, [SP, 4] ; b
  ADD    A, C, A
  LD     B, [SP, 8] ; c
  ADD    A, B
  LD     B, [SP, 12] ; d
  ADD    A, B
  ADD    A, C
.L5:
  ADD    SP, 20
  ADD    SP, 4
  RET
params6:
  SUB    SP, 16
  ST     [SP, 0], A ; a
  ST.H   [SP, 4], B ; b
  ST.B   [SP, 6], C ; c
  ST     [SP, 7], D ; d
  MOV    A, 10
  ST     [SP, 11], A ; i
  MOV.B  A, 'c'
  ST.B   [SP, 15], A ; l
  LD     C, [SP, 0] ; a
  LD.H   D, [SP, 4] ; b
  ADD    A, C, D
  LD.B   B, [SP, 6] ; c
  ADD    A, B
  LD     B, [SP, 7] ; d
  ADD    A, B
  ADD    A, C
  ADD    A, D
.L6:
  ADD    SP, 16
  ADD    SP, 8
  RET
main:
  PUSH   B, C, D, E, F, LR
  SUB    SP, 4
  MOV    A, 1
  MOV    B, 2
  MOV    C, 3
  MOV    D, 4
  MOV    E, 5
  MOV    F, 6
  PUSH   F
  PUSH   E
  CALL   params6
  ST     [SP, 0], A ; i
.L7:
  ADD    SP, 4
  POP    B, C, D, E, F, PC