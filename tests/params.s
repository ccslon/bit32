params0:
  PUSH FP
  MOV FP, SP
  MOV A, 0
  JMP .L0
.L0:
  MOV SP, FP
  POP FP
  RET
params1:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; foo
  JMP .L1
.L1:
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET
params2:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; foo
  LD B, [FP, 4] ; bar
  ADD A, B
  JMP .L2
.L2:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
params3:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 0] ; foo
  LD B, [FP, 4] ; bar
  ADD A, B
  LD B, [FP, 8] ; baz
  ADD A, B
  JMP .L3
.L3:
  MOV SP, FP
  ADD SP, 12
  POP FP
  RET
params4:
  PUSH FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  LD A, [FP, 0] ; foo
  LD B, [FP, 4] ; bar
  ADD A, B
  LD B, [FP, 8] ; baz
  ADD A, B
  LD B, [FP, 12] ; bif
  ADD A, B
  JMP .L4
.L4:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
params5:
  PUSH FP
  SUB SP, 20
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  MOV A, 10
  ST [FP, 16], A ; i
  LD A, [FP, 0] ; a
  LD B, [FP, 4] ; b
  ADD A, B
  LD B, [FP, 8] ; c
  ADD A, B
  LD B, [FP, 12] ; d
  ADD A, B
  LD B, [FP, 24] ; e
  ADD A, B
  JMP .L5
.L5:
  MOV SP, FP
  ADD SP, 20
  POP FP
  RET
params6:
  PUSH FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST.H [FP, 4], B
  ST.B [FP, 6], C
  ST [FP, 7], D
  MOV A, 10
  ST [FP, 11], A ; i
  MOV.B A, 'c'
  ST.B [FP, 15], A ; l
  LD A, [FP, 0] ; a
  LD.H B, [FP, 4] ; b
  ADD A, B
  LD.B B, [FP, 6] ; c
  ADD A, B
  LD B, [FP, 7] ; d
  ADD A, B
  LD B, [FP, 20] ; e
  ADD A, B
  LD B, [FP, 24] ; f
  ADD A, B
  JMP .L6
.L6:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET