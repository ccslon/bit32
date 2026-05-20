array: .space 40
get:
  SUB    SP, 8
  ST     [SP, 0], A ; g
  ST     [SP, 4], B ; i
  LD     B, [SP, 0] ; g
  LD     A, [SP, 4] ; i
  SHL    A, 2
  LD     A, [B, A]
.L0:
  ADD    SP, 8
  RET
set:
  SUB    SP, 12
  ST     [SP, 0], A ; g
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; t
  LD     B, [SP, 8] ; t
  LD     C, [SP, 0] ; g
  LD     A, [SP, 4] ; i
  SHL    A, 2
  ST     [C, A], B
  ADD    SP, 12
  RET
getchar:
  SUB    SP, 8
  ST     [SP, 0], A ; c
  ST     [SP, 4], B ; i
  LD     A, [SP, 0] ; c
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
.L1:
  ADD    SP, 8
  RET
setchar:
  SUB    SP, 9
  ST     [SP, 0], A ; c
  ST     [SP, 4], B ; i
  ST.B   [SP, 8], C ; t
  LD.B   A, [SP, 8] ; t
  LD     B, [SP, 0] ; c
  LD     C, [SP, 4] ; i
  ST.B   [B, C], A
  ADD    SP, 9
  RET
getarray:
  PUSH   B
  SUB    SP, 4
  ST     [SP, 0], A ; i
  LDI    B, =array
  LD     A, [SP, 0] ; i
  SHL    A, 2
  LD     A, [B, A]
.L2:
  ADD    SP, 4
  POP    B
  RET
setarray:
  PUSH   C
  SUB    SP, 8
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; t
  LDI    C, =array
  LD     A, [SP, 0] ; i
  SHL    A, 2
  ST     [C, A], B
  ADD    SP, 8
  POP    C
  RET
getstack:
  SUB    SP, 44
  ST     [SP, 0], A ; i
  LD     A, [SP, 16] ; a
.L3:
  ADD    SP, 44
  RET
setstack:
  PUSH   C
  SUB    SP, 48
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; t
  ADD    C, SP, 8 ; a
  LD     A, [SP, 0] ; i
  SHL    A, 2
  ST     [C, A], B
.L4:
  ADD    SP, 48
  POP    C
  RET