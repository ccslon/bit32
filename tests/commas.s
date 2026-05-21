strrev:
  PUSH   B, C, LR
  SUB    SP, 13
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 4], A ; front
  LD     A, [SP, 0] ; s
  CALL   strlen
  SUB    A, 1
  ST     [SP, 8], A ; back
.L1:
  LD     A, [SP, 4] ; front
  LD     B, [SP, 8] ; back
  CMP    A, B
  JGE    .L3
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; front
  LD.B   A, [A, B]
  ST.B   [SP, 12], A ; temp
  LD     C, [SP, 0] ; s
  LD     A, [SP, 8] ; back
  LD.B   A, [C, A]
  LD     B, [SP, 4] ; front
  ST.B   [C, B], A
  LD.B   A, [SP, 12] ; temp
  LD     B, [SP, 0] ; s
  LD     C, [SP, 8] ; back
  ST.B   [B, C], A
.L2:
  LD     A, [SP, 4] ; front
  ADD    A, 1
  ST     [SP, 4], A ; front
  LD     A, [SP, 8] ; back
  SUB    A, 1
  ST     [SP, 8], A ; back
  JMP    .L1
.L3:
  LD     A, [SP, 0] ; s
.L0:
  ADD    SP, 13
  POP    B, C, PC