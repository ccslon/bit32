get2:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
  LD [FP, 8], C
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
  LD [FP, 0], A
  LD [FP, 4], B
  LD [FP, 8], C
  LD [FP, 12], D
  LD A, [FP, 12] ; t
  LD B, [FP, 0] ; g
  LD C, [FP, 4] ; i
  MUL C, 4
  ADD B, C
  LD B, [B]
  LD C, [FP, 8] ; j
  MUL C, 4
  ADD B, C
  LD [B], A
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
getchar2:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
  LD [FP, 8], C
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
  LD [FP, 0], A
  LD [FP, 4], B
  LD [FP, 8], C
  LD.B [FP, 12], D
  LD.B A, [FP, 12] ; t
  LD B, [FP, 0] ; c
  LD C, [FP, 4] ; i
  MUL C, 4
  ADD B, C
  LD B, [B]
  LD C, [FP, 8] ; j
  ADD B, C
  LD.B [B], A
  MOV SP, FP
  ADD SP, 13
  POP FP
  RET