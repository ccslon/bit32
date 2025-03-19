array: .space 400
get2:
  SUB SP, 12
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  LD A, [SP, 0] ; g
  LD B, [SP, 4] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  LD B, [SP, 8] ; j
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L0
.L0:
  ADD SP, 12
  RET
set2:
  SUB SP, 16
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  ST [SP, 12], D
  LD A, [SP, 12] ; t
  LD B, [SP, 0] ; g
  LD C, [SP, 4] ; i
  MUL C, 4
  ADD B, C
  LD B, [B]
  LD C, [SP, 8] ; j
  MUL C, 4
  ADD B, C
  ST [B], A
  ADD SP, 16
  RET
getchar2:
  SUB SP, 12
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  LD A, [SP, 0] ; c
  LD B, [SP, 4] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  LD B, [SP, 8] ; j
  ADD A, B
  LD.B A, [A]
  JMP .L1
.L1:
  ADD SP, 12
  RET
setchar2:
  SUB SP, 13
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  ST.B [SP, 12], D
  LD.B A, [SP, 12] ; t
  LD B, [SP, 0] ; c
  LD C, [SP, 4] ; i
  MUL C, 4
  ADD B, C
  LD B, [B]
  LD C, [SP, 8] ; j
  ADD B, C
  ST.B [B], A
  ADD SP, 13
  RET
getarray2:
  SUB SP, 8
  ST [SP, 0], A
  ST [SP, 4], B
  LDI A, =array
  LD B, [SP, 0] ; i
  MUL B, 40
  ADD A, B
  LD B, [SP, 4] ; j
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L2
.L2:
  ADD SP, 8
  RET
setarray2:
  SUB SP, 12
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  LD A, [SP, 8] ; t
  LDI B, =array
  LD C, [SP, 0] ; i
  MUL C, 40
  ADD B, C
  LD C, [SP, 4] ; j
  MUL C, 4
  ADD B, C
  ST [B], A
  ADD SP, 12
  RET
getstack:
  SUB SP, 108
  ST [SP, 0], A
  ST [SP, 4], B
  ADD A, SP, 8
  LD B, [SP, 0] ; i
  MUL B, 20
  ADD A, B
  LD B, [SP, 4] ; j
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L3
.L3:
  ADD SP, 108
  RET
getstack:
  SUB SP, 112
  ST [SP, 0], A
  ST [SP, 4], B
  ST [SP, 8], C
  LD A, [SP, 8] ; t
  ADD B, SP, 12
  LD C, [SP, 0] ; i
  MUL C, 20
  ADD B, C
  LD C, [SP, 4] ; j
  MUL C, 4
  ADD B, C
  ST [B], A
.L4:
  ADD SP, 112
  RET