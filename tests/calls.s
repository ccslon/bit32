baz:
  SUB SP, 8
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; y
  LD B, [SP, 4] ; z
  MUL A, B
  JMP .L0
.L0:
  ADD SP, 8
  RET
bar:
  SUB SP, 8
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; x
  LD B, [SP, 4] ; y
  MUL A, B
  JMP .L1
.L1:
  ADD SP, 8
  RET
foo:
  PUSH D, E, LR
  SUB SP, 12
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  LD C, [SP, 0] ; x
  LD D, [SP, 4] ; y
  MOV A, C
  MOV B, D
  CALL bar
  MOV C, A
  LD D, [SP, 4] ; y
  LD E, [SP, 8] ; z
  MOV A, D
  MOV B, E
  CALL baz
  MOV D, A
  ADD C, D
  JMP .L2
.L2:
  MOV A, C
  ADD SP, 12
  POP D, E, PC