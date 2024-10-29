baz:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; y
  LD B, [FP, 4] ; z
  MUL A, B
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
bar:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; x
  LD B, [FP, 4] ; y
  MUL A, B
  JMP .L1
.L1:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
foo:
  PUSH LR, D, E, FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD C, [FP, 0] ; x
  LD D, [FP, 4] ; y
  MOV A, C
  MOV B, D
  CALL bar
  MOV C, A
  LD D, [FP, 4] ; y
  LD E, [FP, 8] ; z
  MOV A, D
  MOV B, E
  CALL baz
  MOV D, A
  ADD C, D
  JMP .L2
.L2:
  MOV A, C
  MOV SP, FP
  ADD SP, 12
  POP PC, D, E, FP