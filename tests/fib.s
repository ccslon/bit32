fib:
  PUSH LR, B, C, FP
  SUB SP, 4
  MOV FP, SP
  LD [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 1
  JNE .L2
  MOV B, 0
  JMP .L0
.L2:
  LD B, [FP, 0] ; n
  CMP B, 2
  JNE .L3
  MOV B, 1
  JMP .L0
.L3:
  LD B, [FP, 0] ; n
  SUB B, 1
  MOV A, B
  CALL fib
  MOV B, A
  LD C, [FP, 0] ; n
  SUB C, 2
  MOV A, C
  CALL fib
  MOV C, A
  ADD B, C
  JMP .L0
.L0:
  MOV A, B
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, FP
fib2:
  PUSH LR, B, C, FP
  SUB SP, 4
  MOV FP, SP
  LD [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 1
  JEQ .L7
  CMP B, 2
  JEQ .L8
  JMP .L9
.L7:
  MOV B, 0
  JMP .L4
.L8:
  MOV B, 1
  JMP .L4
.L9:
  LD B, [FP, 0] ; n
  SUB B, 1
  MOV A, B
  CALL fib
  MOV B, A
  LD C, [FP, 0] ; n
  SUB C, 2
  MOV A, C
  CALL fib
  MOV C, A
  ADD B, C
  JMP .L4
.L6:
.L4:
  MOV A, B
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, FP