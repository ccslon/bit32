test:
  PUSH A, B, FP
  SUB SP, 8
  MOV FP, SP
  MOV A, 0
  ST [FP, 0], A ; i
.L0:
  LD A, [FP, 0] ; i
  CMP A, 10
  JGE .L2
  LD A, [FP, 4] ; minN
  LD B, [FP, 0] ; i
  CMP A, B
  JLE .L4
  LD A, [FP, 0] ; i
  JMP .L3
.L4:
  LD A, [FP, 4] ; minN
.L3:
  ST [FP, 4], A ; minN
  LD A, [FP, 4] ; minN
  ADD B, A, 1
  ST [FP, 4], B ; minN
.L1:
  LD A, [FP, 0] ; i
  ADD B, A, 1
  ST [FP, 0], B ; i
  JMP .L0
.L2:
  MOV SP, FP
  ADD SP, 8
  POP A, B, FP
  RET