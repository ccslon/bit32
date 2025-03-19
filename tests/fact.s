fact:
  PUSH B, C, LR
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; n
  CMP A, 0
  JNE .L1
  MOV B, 1
  JMP .L0
.L1:
  LD B, [SP, 0] ; n
  LD C, [SP, 0] ; n
  SUB C, 1
  MOV A, C
  CALL fact
  MOV C, A
  MUL B, C
  JMP .L0
.L0:
  MOV A, B
  ADD SP, 4
  POP B, C, PC