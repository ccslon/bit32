div:
  SUB    SP, 16
  ST     [SP, 0], A ; num
  ST     [SP, 4], B ; den
  MOV    A, 3
  ST     [SP, 8], A ; ans.quot
  MOV    A, 4
  ST     [SP, 12], A ; ans.rem
  ADD    A, SP, 8 ; ans
.L0:
  ADD    SP, 16
  RET
print_int:
  PUSH   B, C, LR
  SUB    SP, 12
  ST     [SP, 0], A ; num
  MOV    B, 10
  CALL   div
  ADD    C, SP, 4 ; ans
  LD     B, [A, 0]
  ST     [C, 0], B
  LD     A, [A, 4]
  ST     [C, 4], A
  ADD    SP, 12
  POP    B, C, PC