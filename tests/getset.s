array: .space 40
get:
  SUB    SP, 8
  ST     [SP, 0], A ; g
  ST     [SP, 4], B ; i
  LD     A, [SP, 0] ; g
  LD     B, [SP, 4] ; i
  MUL    B, 4
  LD     A, [A, B]
.L0:
  ADD    SP, 8
  RET
set:
  SUB    SP, 12
  ST     [SP, 0], A ; g
  ST     [SP, 4], B ; i
  ST     [SP, 8], C ; t
  LD     A, [SP, 8] ; t
  LD     B, [SP, 0] ; g
  LD     C, [SP, 4] ; i
  MUL    C, 4
  ST     [B, C], A
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
  LDI    A, =array
  LD     B, [SP, 0] ; i
  MUL    B, 4
  LD     A, [A, B]
.L2:
  ADD    SP, 4
  POP    B
  RET
setarray:
  PUSH   C
  SUB    SP, 8
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; t
  LD     A, [SP, 4] ; t
  LDI    B, =array
  LD     C, [SP, 0] ; i
  MUL    C, 4
  ST     [B, C], A
  ADD    SP, 8
  POP    C
  RET
getstack:
  PUSH   B
  SUB    SP, 44
  ST     [SP, 0], A ; i
  ADD    A, SP, 4 ; a
  LD     B, [SP, 0] ; i
  MUL    B, 4
  LD     A, [A, B]
.L3:
  ADD    SP, 44
  POP    B
  RET
getstack:
  PUSH   C
  SUB    SP, 48
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; t
  LD     A, [SP, 4] ; t
  ADD    B, SP, 8 ; a
  LD     C, [SP, 0] ; i
  MUL    C, 4
  ST     [B, C], A
.L4:
  ADD    SP, 48
  POP    C
  RET