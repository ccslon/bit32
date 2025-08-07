array: .space 400
get2:
  SUB    SP, 12
  ST     [SP, 0], A ; g
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; j
  LD     A, [SP, 0] ; g
  LD     B, [SP, 4] ; i
  SHL    B, 2
  LD     A, [A, B]
  LD     B, [SP, 8] ; j
  SHL    B, 2
  LD     A, [A, B]
.L0:
  ADD    SP, 12
  RET
set2:
  SUB    SP, 16
  ST     [SP, 0], A ; g
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; j
  ST     [SP, 12], D ; t
  LD     A, [SP, 12] ; t
  LD     B, [SP, 0] ; g
  LD     C, [SP, 4] ; i
  SHL    C, 2
  LD     B, [B, C]
  LD     C, [SP, 8] ; j
  SHL    C, 2
  ST     [B, C], A
  ADD    SP, 16
  RET
getchar2:
  SUB    SP, 12
  ST     [SP, 0], A ; c
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; j
  LD     A, [SP, 0] ; c
  LD     B, [SP, 4] ; i
  SHL    B, 2
  LD     A, [A, B]
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
  LD.B   A, [SP, 12] ; t
  LD     B, [SP, 0] ; c
  LD     C, [SP, 4] ; i
  SHL    C, 2
  LD     B, [B, C]
  LD     C, [SP, 8] ; j
  ST.B   [B, C], A
  ADD    SP, 13
  RET
getarray2:
  SUB    SP, 8
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; j
  LDI    A, =array
  LD     B, [SP, 0] ; i
  MUL    B, 40
  ADD    A, B
  LD     B, [SP, 4] ; j
  SHL    B, 2
  LD     A, [A, B]
.L2:
  ADD    SP, 8
  RET
setarray2:
  SUB    SP, 12
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; j
  ST     [SP, 8], C ; t
  LD     A, [SP, 8] ; t
  LDI    B, =array
  LD     C, [SP, 0] ; i
  MUL    C, 40
  ADD    B, C
  LD     C, [SP, 4] ; j
  SHL    C, 2
  ST     [B, C], A
  ADD    SP, 12
  RET
getstack:
  SUB    SP, 108
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; j
  ADD    A, SP, 8 ; a
  LD     B, [SP, 0] ; i
  MUL    B, 20
  ADD    A, B
  LD     B, [SP, 4] ; j
  SHL    B, 2
  LD     A, [A, B]
.L3:
  ADD    SP, 108
  RET
getstack:
  SUB    SP, 112
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; j
  ST     [SP, 8], C ; t
  LD     A, [SP, 8] ; t
  ADD    B, SP, 12 ; a
  LD     C, [SP, 0] ; i
  MUL    C, 20
  ADD    B, C
  LD     C, [SP, 4] ; j
  SHL    C, 2
  ST     [B, C], A
.L4:
  ADD    SP, 112
  RET