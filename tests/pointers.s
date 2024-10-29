change:
  PUSH B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; n
  LD A, [A]
  ADD A, 10
  LD B, [FP, 0] ; n
  ST [B], A
  MOV SP, FP
  ADD SP, 4
  POP B, FP
  RET
foo:
  PUSH LR, B, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; m
  MUL B, 5
  ST [FP, 4], B ; n
  ADD B, FP, 4
  MOV A, B
  CALL change
  MOV SP, FP
  ADD SP, 8
  POP PC, B, FP
bar:
  PUSH LR, C, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD B, [FP, 0] ; str
  MOV A, B
  CALL print
  LD B, [FP, 0] ; str
  LD C, [FP, 4] ; i
  ADD B, C
  MOV A, B
  CALL print
  MOV SP, FP
  ADD SP, 8
  POP PC, C, FP