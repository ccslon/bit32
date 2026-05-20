array: .space 400
get2:
  SUB    SP, 12
  ST     [SP, 0], A ; g
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; j
  LD     B, [SP, 0] ; g
  LD     A, [SP, 4] ; i
  SHL    A, 2
  LD     B, [B, A]
  LD     A, [SP, 8] ; j
  SHL    A, 2
  LD     A, [B, A]
.L0:
  ADD    SP, 12
  RET
set2:
  SUB    SP, 16
  ST     [SP, 0], A ; g
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; j
  ST     [SP, 12], D ; t
  LD     C, [SP, 12] ; t
  LD     B, [SP, 0] ; g
  LD     A, [SP, 4] ; i
  SHL    A, 2
  LD     B, [B, A]
  LD     A, [SP, 8] ; j
  SHL    A, 2
  ST     [B, A], C
  ADD    SP, 16
  RET
getchar2:
  SUB    SP, 12
  ST     [SP, 0], A ; c
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; j
  LD     B, [SP, 0] ; c
  LD     A, [SP, 4] ; i
  SHL    A, 2
  LD     A, [B, A]
  LD     B, [SP, 8] ; j
  LD.B   A, [A, B]
.L1:
  ADD    SP, 12
  RET
setchar2:
  SUB    SP, 13
  ST     [SP, 0], A ; c
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; j
  ST.B   [SP, 12], D ; t
  LD.B   C, [SP, 12] ; t
  LD     B, [SP, 0] ; c
  LD     A, [SP, 4] ; i
  SHL    A, 2
  LD     A, [B, A]
  LD     B, [SP, 8] ; j
  ST.B   [A, B], C
  ADD    SP, 13
  RET
getarray2:
  SUB    SP, 8
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; j
  LDI    B, =array
  LD     A, [SP, 0] ; i
  MUL    A, 40
  ADD    B, A
  LD     A, [SP, 4] ; j
  SHL    A, 2
  LD     A, [B, A]
.L2:
  ADD    SP, 8
  RET
setarray2:
  SUB    SP, 12
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; j
  ST     [SP, 8], C ; t
  LDI    B, =array
  LD     A, [SP, 0] ; i
  MUL    A, 40
  ADD    B, A
  LD     A, [SP, 4] ; j
  SHL    A, 2
  ST     [B, A], C
  ADD    SP, 12
  RET
getstack:
  SUB    SP, 108
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; j
  ADD    B, SP, 8 ; a
  LD     A, [SP, 0] ; i
  MUL    A, 20
  ADD    B, A
  LD     A, [SP, 4] ; j
  SHL    A, 2
  LD     A, [B, A]
.L3:
  ADD    SP, 108
  RET
getstack:
  SUB    SP, 112
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; j
  ST     [SP, 8], C ; t
  ADD    B, SP, 12 ; a
  LD     A, [SP, 0] ; i
  MUL    A, 20
  ADD    B, A
  LD     A, [SP, 4] ; j
  SHL    A, 2
  ST     [B, A], C
.L4:
  ADD    SP, 112
  RET