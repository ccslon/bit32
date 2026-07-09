fact:
  PUSH   B, LR
  SUB    SP, 4
  ST     [SP, 0], A ; n
  CMP    A, 0
  JNE    .L1
  MOV    A, 1
  JMP    .L0
.L1:
  LD     B, [SP, 0] ; n
  SUB    A, B, 1
  CALL   fact
  MUL    A, B, A
.L0:
  ADD    SP, 4
  POP    B, PC