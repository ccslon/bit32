params0:
  MOV A, 0
  JMP .L0
.L0:
  RET
params1:
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; foo
  JMP .L1
.L1:
  ADD SP, 4
  RET
params2:
  SUB SP, 8
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; foo
  LD B, [SP, 4] ; bar
  ADD A, B
  JMP .L2
.L2:
  ADD SP, 8
  RET
params3:
  SUB SP, 12
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  LD A, [SP, 0] ; foo
  LD B, [SP, 4] ; bar
  ADD A, B
  LD B, [SP, 8] ; baz
  ADD A, B
  JMP .L3
.L3:
  ADD SP, 12
  RET
params4:
  SUB SP, 16
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  ST [SP, 12], D
  LD A, [SP, 0] ; foo
  LD B, [SP, 4] ; bar
  ADD A, B
  LD B, [SP, 8] ; baz
  ADD A, B
  LD B, [SP, 12] ; bif
  ADD A, B
  JMP .L4
.L4:
  ADD SP, 16
  RET
params5:
  SUB SP, 20
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  ST [SP, 12], D
  MOV A, 10
  ST [SP, 16], A ; i
  LD A, [SP, 0] ; a
  LD B, [SP, 4] ; b
  ADD A, B
  LD B, [SP, 8] ; c
  ADD A, B
  LD B, [SP, 12] ; d
  ADD A, B
  LD B, [SP, 20] ; e
  ADD A, B
  JMP .L5
.L5:
  ADD SP, 20
  RET
params6:
  SUB SP, 16
  ST [SP, 0], A
  ST.H [SP, 4], B
  ST.B [SP, 6], C
  ST [SP, 7], D
  MOV A, 10
  ST [SP, 11], A ; i
  MOV.B A, 'c'
  ST.B [SP, 15], A ; l
  LD A, [SP, 0] ; a
  LD.H B, [SP, 4] ; b
  ADD A, B
  LD.B B, [SP, 6] ; c
  ADD A, B
  LD B, [SP, 7] ; d
  ADD A, B
  LD B, [SP, 16] ; e
  ADD A, B
  LD B, [SP, 20] ; f
  ADD A, B
  JMP .L6
.L6:
  ADD SP, 16
  RET