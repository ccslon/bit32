foo:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; bar
  CMP A, 3
  JLE .L1
  MOV A, 3
  ST [FP, 0], A ; bar
  JMP baz
.L1:
  LD A, [FP, 0] ; bar
  MUL A, 3
  ST [FP, 0], A ; bar
baz:
  LD A, [FP, 0] ; bar
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET