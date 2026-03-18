strrev:
  PUSH   B, C, LR
  SUB    SP, 13
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 4], A ; front
  LD     A, [SP, 0] ; s
  CALL   strlen
  MOV    B, A
  SUB    B, 1
  ST     [SP, 8], B ; back
.L1:
  LD     A, [SP, 4] ; front
  LD     B, [SP, 8] ; back
  CMP    A, B
  JGE    .L3
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; front
  LD.B   A, [A, B]
  ST.B   [SP, 12], A ; temp
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; back
  LD.B   A, [A, B]
  LD     B, [SP, 0] ; s
  LD     C, [SP, 4] ; front
  ST.B   [B, C], A
  LD.B   A, [SP, 12] ; temp
  LD     B, [SP, 0] ; s
  LD     C, [SP, 8] ; back
  ST.B   [B, C], A
.L2:
  LD     A, [SP, 4] ; front
  ADD    B, A, 1
  ST     [SP, 4], B ; front
  LD     A, [SP, 8] ; back
  SUB    B, A, 1
  ST     [SP, 8], B ; back
  JMP    .L1
.L3:
  LD     B, [SP, 0] ; s
.L0:
  MOV    A, B
  ADD    SP, 13
  POP    B, C, PC