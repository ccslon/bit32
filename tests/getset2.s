array: .space 400
get2:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 0] ; g
  LD B, [FP, 4] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  LD B, [FP, 8] ; j
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 12
  POP FP
  RET
set2:
  PUSH FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  LD A, [FP, 12] ; t
  LD B, [FP, 0] ; g
  LD C, [FP, 4] ; i
  MUL C, 4
  ADD B, C
  LD B, [B]
  LD C, [FP, 8] ; j
  MUL C, 4
  ADD B, C
  ST [B], A
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
getchar2:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 0] ; c
  LD B, [FP, 4] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  LD B, [FP, 8] ; j
  ADD A, B
  LD.B A, [A]
  JMP .L1
.L1:
  MOV SP, FP
  ADD SP, 12
  POP FP
  RET
setchar2:
  PUSH FP
  SUB SP, 13
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST.B [FP, 12], D
  LD.B A, [FP, 12] ; t
  LD B, [FP, 0] ; c
  LD C, [FP, 4] ; i
  MUL C, 4
  ADD B, C
  LD B, [B]
  LD C, [FP, 8] ; j
  ADD B, C
  ST.B [B], A
  MOV SP, FP
  ADD SP, 13
  POP FP
  RET
getarray2:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LDI A, =array
  LD B, [FP, 0] ; i
  MUL B, 40
  ADD A, B
  LD B, [FP, 4] ; j
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L2
.L2:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
setarray2:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 8] ; t
  LDI B, =array
  LD C, [FP, 0] ; i
  MUL C, 40
  ADD B, C
  LD C, [FP, 4] ; j
  MUL C, 4
  ADD B, C
  ST [B], A
  MOV SP, FP
  ADD SP, 12
  POP FP
  RET
getstack:
  PUSH FP
  SUB SP, 108
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ADD A, FP, 8
  LD B, [FP, 0] ; i
  MUL B, 20
  ADD A, B
  LD B, [FP, 4] ; j
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L3
.L3:
  MOV SP, FP
  ADD SP, 108
  POP FP
  RET
getstack:
  PUSH FP
  SUB SP, 112
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 8] ; t
  ADD B, FP, 12
  LD C, [FP, 0] ; i
  MUL C, 20
  ADD B, C
  LD C, [FP, 4] ; j
  MUL C, 4
  ADD B, C
  ST [B], A
.L4:
  MOV SP, FP
  ADD SP, 112
  POP FP
  RET