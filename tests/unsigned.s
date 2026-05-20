foo:
  PUSH   C
  SUB    SP, 32
  ST     [SP, 0], A ; u
  ST     [SP, 4], B ; i
  LD     B, [SP, 0] ; u
  LD     C, [SP, 4] ; i
  CMP    B, C
  MOVEQ  A, 1
  MOVNE  A, 0
  ST     [SP, 8], A ; a
  CMP    B, C
  MOVNE  A, 1
  MOVEQ  A, 0
  ST     [SP, 12], A ; b
  CMP    B, C
  MOVHI  A, 1
  MOVLS  A, 0
  ST     [SP, 16], A ; c
  CMP    B, C
  MOVCC  A, 1
  MOVCS  A, 0
  ST     [SP, 20], A ; d
  CMP    B, C
  MOVCS  A, 1
  MOVCC  A, 0
  ST     [SP, 24], A ; e
  CMP    B, C
  MOVLS  A, 1
  MOVHI  A, 0
  ST     [SP, 28], A ; f
.L0:
  ADD    SP, 32
  POP    C
  RET