foo:
  PUSH FP
  SUB SP, 32
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
  LD A, [FP, 0] ; u
  LD B, [FP, 4] ; i
  CMP A, B
  MOVEQ A, 1
  MOVNE A, 0
  LD [FP, 8], A ; a
  LD A, [FP, 0] ; u
  LD B, [FP, 4] ; i
  CMP A, B
  MOVNE A, 1
  MOVEQ A, 0
  LD [FP, 12], A ; b
  LD A, [FP, 0] ; u
  LD B, [FP, 4] ; i
  CMP A, B
  MOVHI A, 1
  MOVLS A, 0
  LD [FP, 16], A ; c
  LD A, [FP, 0] ; u
  LD B, [FP, 4] ; i
  CMP A, B
  MOVCC A, 1
  MOVCS A, 0
  LD [FP, 20], A ; d
  LD A, [FP, 0] ; u
  LD B, [FP, 4] ; i
  CMP A, B
  MOVCS A, 1
  MOVCC A, 0
  LD [FP, 24], A ; e
  LD A, [FP, 0] ; u
  LD B, [FP, 4] ; i
  CMP A, B
  MOVLS A, 1
  MOVHI A, 0
  LD [FP, 28], A ; f
.L0:
  MOV SP, FP
  ADD SP, 32
  POP FP
  RET