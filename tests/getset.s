array: .space 40
get:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; g
  LD B, [FP, 4] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
set:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 8] ; t
  LD B, [FP, 0] ; g
  LD C, [FP, 4] ; i
  MUL C, 4
  ADD B, C
  ST [B], A
  MOV SP, FP
  ADD SP, 12
  POP FP
  RET
getchar:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; c
  LD B, [FP, 4] ; i
  ADD A, B
  LD.B A, [A]
  JMP .L1
.L1:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
setchar:
  PUSH FP
  SUB SP, 9
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST.B [FP, 8], C
  LD.B A, [FP, 8] ; t
  LD B, [FP, 0] ; c
  LD C, [FP, 4] ; i
  ADD B, C
  ST.B [B], A
  MOV SP, FP
  ADD SP, 9
  POP FP
  RET
getarray:
  PUSH B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LDI A, =array
  LD B, [FP, 0] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L2
.L2:
  MOV SP, FP
  ADD SP, 4
  POP B, FP
  RET
setarray:
  PUSH C, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 4] ; t
  LDI B, =array
  LD C, [FP, 0] ; i
  MUL C, 4
  ADD B, C
  ST [B], A
  MOV SP, FP
  ADD SP, 8
  POP C, FP
  RET
getstack:
  PUSH B, FP
  SUB SP, 44
  MOV FP, SP
  ST [FP, 0], A
  ADD A, FP, 4
  LD B, [FP, 0] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L3
.L3:
  MOV SP, FP
  ADD SP, 44
  POP B, FP
  RET
getstack:
  PUSH C, FP
  SUB SP, 48
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 4] ; t
  ADD B, FP, 8
  LD C, [FP, 0] ; i
  MUL C, 4
  ADD B, C
  ST [B], A
.L4:
  MOV SP, FP
  ADD SP, 48
  POP C, FP
  RET