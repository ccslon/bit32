fib:
  PUSH   B, LR
  SUB    SP, 4
  ST     [SP, 0], A ; n
  CMP    A, 1
  JNE    .L2
  MOV    A, 0
  JMP    .L0
.L2:
  LD     A, [SP, 0] ; n
  CMP    A, 2
  JNE    .L3
  MOV    A, 1
  JMP    .L0
.L3:
  LD     A, [SP, 0] ; n
  SUB    A, 1
  CALL   fib
  MOV    B, A
  LD     A, [SP, 0] ; n
  SUB    A, 2
  CALL   fib
  ADD    A, B, A
.L0:
  ADD    SP, 4
  POP    B, PC
fib2:
  PUSH   B, LR
  SUB    SP, 4
  ST     [SP, 0], A ; n
  CMP    A, 1
  JEQ    .L7
  CMP    A, 2
  JEQ    .L8
  JMP    .L9
.L7:
  MOV    A, 0
  JMP    .L4
.L8:
  MOV    A, 1
  JMP    .L4
.L9:
  LD     A, [SP, 0] ; n
  SUB    A, 1
  CALL   fib
  MOV    B, A
  LD     A, [SP, 0] ; n
  SUB    A, 2
  CALL   fib
  ADD    A, B, A
.L6:
.L4:
  ADD    SP, 4
  POP    B, PC