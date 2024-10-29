.S0: "Cloud\0"
get_name:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; cat
  LD A, [A, 0] ; name
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET
sqr:
  PUSH B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; n
  LD B, [FP, 0] ; n
  MUL A, B
  JMP .L1
.L1:
  MOV SP, FP
  ADD SP, 4
  POP B, FP
  RET
sum:
  PUSH LR, C, FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  MOV B, 0
  ST [FP, 8], B ; s
  MOV B, 0
  ST [FP, 12], B ; i
.L3:
  LD B, [FP, 12] ; i
  LD C, [FP, 0] ; n
  CMP B, C
  JGE .L5
  LD B, [FP, 8] ; s
  LD C, [FP, 12] ; i
  MOV A, C
  LD C, [FP, 4] ; f
  CALL C
  MOV C, A
  ADD B, C
  ST [FP, 8], B ; s
.L4:
  LD B, [FP, 12] ; i
  ADD C, B, 1
  ST [FP, 12], C ; i
  JMP .L3
.L5:
  LD B, [FP, 8] ; s
  JMP .L2
.L2:
  MOV A, B
  MOV SP, FP
  ADD SP, 16
  POP PC, C, FP
main:
  PUSH LR, B, C, D, FP
  SUB SP, 20
  MOV FP, SP
  LDI C, =.S0
  ADD D, FP, 0
  ST [D, 0], C ; name
  MOV C, 15
  ADD D, FP, 0
  ST [D, 4], C ; age
  LDI C, =get_name
  ADD D, FP, 0
  ST [D, 8], C ; get_name
  ADD C, FP, 0
  MOV A, C
  ADD C, FP, 0
  LD C, [C, 8] ; get_name
  CALL C
  MOV C, A
  ST [FP, 12], C ; name
  MOV C, 10
  LDI D, =sqr
  MOV A, C
  MOV B, D
  CALL sum
  MOV C, A
  ST [FP, 16], C ; n
  MOV C, 0
  JMP .L6
.L6:
  MOV A, C
  MOV SP, FP
  ADD SP, 20
  POP PC, B, C, D, FP