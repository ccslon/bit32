test:
  PUSH   A, B
  SUB    SP, 8
  MOV    A, 0
  ST     [SP, 0], A ; i
.L0:
  LD     A, [SP, 0] ; i
  CMP    A, 10
  JGE    .L2
  LD     A, [SP, 4] ; minN
  LD     B, [SP, 0] ; i
  CMP    A, B
  JLE    .L4
  LD     A, [SP, 0] ; i
  JMP    .L3
.L4:
  LD     V04, [SP, 4] ; minN
.L3:
  ST     [SP, 4], A ; minN
  ADD    A, 1
  ST     [SP, 4], A ; minN
.L1:
  LD     A, [SP, 0] ; i
  ADD    A, 1
  ST     [SP, 0], A ; i
  JMP    .L0
.L2:
  ADD    SP, 8
  POP    A, B
  RET