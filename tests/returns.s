div:
  SUB    SP, 16
  ST     [SP, 0], A ; num
  ST     [SP, 4], B ; den
  MOV    A, 3
  ST     [SP, 8], A ; ans
  MOV    A, 4
  ST     [SP, 12], A ; ans
  ADD    A, SP, 8 ; ans
  JMP    .L0
.L0:
  ADD    SP, 16
  RET
print_int:
  PUSH   B, C, LR
  SUB    SP, 12
  ST     [SP, 0], A ; num
  LD     A, [SP, 0] ; num
  MOV    B, 10
  CALL   div
  ADD    B, SP, 4 ; ans
  LD     C, [A, 0]
  ST     [B, 0], C
  LD     C, [A, 4]
  ST     [B, 4], C
  ADD    SP, 12
  POP    B, C, PC