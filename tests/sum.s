sqr:
  PUSH B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; n
  LD B, [FP, 0] ; n
  MUL A, B
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 4
  POP B, FP
  RET
sum:
  PUSH LR, C, FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  MOV B, 0
  ST [FP, 8], B ; sum
  MOV B, 0
  ST [FP, 12], B ; i
.L2:
  LD B, [FP, 12] ; i
  LD C, [FP, 0] ; n
  CMP B, C
  JGE .L4
  LD B, [FP, 8] ; sum
  LD C, [FP, 12] ; i
  MOV A, C
  LD C, [FP, 4] ; f
  CALL C
  MOV C, A
  ADD B, C
  ST [FP, 8], B ; sum
.L3:
  LD B, [FP, 12] ; i
  ADD C, B, 1
  ST [FP, 12], C ; i
  JMP .L2
.L4:
  LD B, [FP, 8] ; sum
  JMP .L1
.L1:
  MOV A, B
  MOV SP, FP
  ADD SP, 16
  POP PC, C, FP
main:
  PUSH LR, B, C, D, FP
  MOV FP, SP
  MOV C, 5
  LDI D, =sqr
  MOV A, C
  MOV B, D
  CALL sum
  MOV C, A
  JMP .L5
.L5:
  MOV A, C
  MOV SP, FP
  POP PC, B, C, D, FP