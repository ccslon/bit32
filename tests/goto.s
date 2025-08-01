foo:
  SUB    SP, 4
  ST     [SP, 0], A ; bar
  LD     A, [SP, 0] ; bar
  CMP    A, 3
  JLE    .L1
  MOV    A, 3
  ST     [SP, 0], A ; bar
  JMP    foo_baz
.L1:
  LD     A, [SP, 0] ; bar
  MUL    A, 3
  ST     [SP, 0], A ; bar
foo_baz:
  LD     A, [SP, 0] ; bar
.L0:
  ADD    SP, 4
  RET