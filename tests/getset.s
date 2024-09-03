get:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
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
  LD [FP, 0], A
  LD [FP, 4], B
  LD [FP, 8], C
  LD A, [FP, 8] ; t
  LD B, [FP, 0] ; g
  LD C, [FP, 4] ; i
  MUL C, 4
  ADD B, C
  LD [B], A
  MOV SP, FP
  ADD SP, 12
  POP FP
  RET
getchar:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
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
  LD [FP, 0], A
  LD [FP, 4], B
  LD.B [FP, 8], C
  LD.B A, [FP, 8] ; t
  LD B, [FP, 0] ; c
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B [B], A
  MOV SP, FP
  ADD SP, 9
  POP FP
  RET