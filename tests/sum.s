sqr:
  PUSH B
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; n
  LD B, [SP, 0] ; n
  MUL A, B
  JMP .L0
.L0:
  ADD SP, 4
  POP B
  RET
sum:
  PUSH C, LR
  SUB SP, 16
  ST [SP, 0], A
  ST [SP, 4], B
  MOV A, 0
  ST [SP, 8], A ; sum
  MOV A, 0
  ST [SP, 12], A ; i
.L2:
  LD A, [SP, 12] ; i
  LD B, [SP, 0] ; n
  CMP A, B
  JGE .L4
  LD B, [SP, 8] ; sum
  LD C, [SP, 12] ; i
  MOV A, C
  LD C, [SP, 4] ; f
  CALL C
  MOV C, A
  ADD B, C
  ST [SP, 8], B ; sum
.L3:
  LD A, [SP, 12] ; i
  ADD B, A, 1
  ST [SP, 12], B ; i
  JMP .L2
.L4:
  LD B, [SP, 8] ; sum
  JMP .L1
.L1:
  MOV A, B
  ADD SP, 16
  POP C, PC
main:
  PUSH B, C, D, LR
  MOV C, 5
  LDI D, =sqr
  MOV A, C
  MOV B, D
  CALL sum
  MOV C, A
  JMP .L5
.L5:
  MOV A, C
  POP B, C, D, PC