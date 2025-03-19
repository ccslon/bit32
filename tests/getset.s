array: .space 40
get:
  SUB SP, 8
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; g
  LD B, [SP, 4] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L0
.L0:
  ADD SP, 8
  RET
set:
  SUB SP, 12
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  LD A, [SP, 8] ; t
  LD B, [SP, 0] ; g
  LD C, [SP, 4] ; i
  MUL C, 4
  ADD B, C
  ST [B], A
  ADD SP, 12
  RET
getchar:
  SUB SP, 8
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; c
  LD B, [SP, 4] ; i
  ADD A, B
  LD.B A, [A]
  JMP .L1
.L1:
  ADD SP, 8
  RET
setchar:
  SUB SP, 9
  ST [SP, 0], A
  ST [SP, 4], B
  ST.B [SP, 8], C
  LD.B A, [SP, 8] ; t
  LD B, [SP, 0] ; c
  LD C, [SP, 4] ; i
  ADD B, C
  ST.B [B], A
  ADD SP, 9
  RET
getarray:
  PUSH B
  SUB SP, 4
  ST [SP, 0], A
  LDI A, =array
  LD B, [SP, 0] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L2
.L2:
  ADD SP, 4
  POP B
  RET
setarray:
  PUSH C
  SUB SP, 8
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 4] ; t
  LDI B, =array
  LD C, [SP, 0] ; i
  MUL C, 4
  ADD B, C
  ST [B], A
  ADD SP, 8
  POP C
  RET
getstack:
  PUSH B
  SUB SP, 44
  ST [SP, 0], A
  ADD A, SP, 4
  LD B, [SP, 0] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L3
.L3:
  ADD SP, 44
  POP B
  RET
getstack:
  PUSH C
  SUB SP, 48
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 4] ; t
  ADD B, SP, 8
  LD C, [SP, 0] ; i
  MUL C, 4
  ADD B, C
  ST [B], A
.L4:
  ADD SP, 48
  POP C
  RET