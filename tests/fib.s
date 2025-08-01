fib:
  PUSH   B, C, LR
  SUB    SP, 4
  ST     [SP, 0], A ; n
  LD     A, [SP, 0] ; n
  CMP    A, 1
  JNE    .L2
  MOV    B, 0
  JMP    .L0
.L2:
  LD     A, [SP, 0] ; n
  CMP    A, 2
  JNE    .L3
  MOV    B, 1
  JMP    .L0
.L3:
  LD     B, [SP, 0] ; n
  SUB    A, B, 1
  CALL   fib
  MOV    B, A
  LD     C, [SP, 0] ; n
  SUB    A, C, 2
  CALL   fib
  ADD    B, A
.L0:
  MOV    A, B
  ADD    SP, 4
  POP    B, C, PC
fib2:
  PUSH   B, C, LR
  SUB    SP, 4
  ST     [SP, 0], A ; n
  LD     A, [SP, 0] ; n
  CMP    A, 1
  JEQ    .L7
  CMP    A, 2
  JEQ    .L8
  JMP    .L9
.L7:
  MOV    B, 0
  JMP    .L4
.L8:
  MOV    B, 1
  JMP    .L4
.L9:
  LD     B, [SP, 0] ; n
  SUB    A, B, 1
  CALL   fib
  MOV    B, A
  LD     C, [SP, 0] ; n
  SUB    A, C, 2
  CALL   fib
  ADD    B, A
.L6:
.L4:
  MOV    A, B
  ADD    SP, 4
  POP    B, C, PC