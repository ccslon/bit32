.S0: "%u\n\0"
.S1: "(STR, \"%s\")\0"
.S2: "(NUM, %d)\0"
.S3: "(CHAR, '%c')\0"
.S4: "Hello!\0"
func1:
  PUSH LR, A, B, C, D, FP
  SUB SP, 4
  MOV FP, SP
  MOV C, 127
  ADD D, FP, 0
  ADD D, 0
  ST.B [D], C
  MOV C, 0
  ADD D, FP, 0
  ADD D, 1
  ST.B [D], C
  MOV C, 0
  ADD D, FP, 0
  ADD D, 2
  ST.B [D], C
  MOV C, 1
  ADD D, FP, 0
  ADD D, 3
  ST.B [D], C
  LDI C, =.S0
  LD D, [FP, 0] ; i
  MOV A, C
  MOV B, D
  CALL printf
  MOV SP, FP
  ADD SP, 4
  POP PC, A, B, C, D, FP
intToken:
  PUSH B, FP
  SUB SP, 9
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 1
  ADD B, FP, 4
  ST.B [B, 0], A ; type
  LD A, [FP, 0] ; num
  ADD B, FP, 4
  ST [B, 1], A ; num
  ADD A, FP, 4
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 9
  POP B, FP
  RET
strToken:
  PUSH B, FP
  SUB SP, 9
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 2
  ADD B, FP, 4
  ST.B [B, 0], A ; type
  LD A, [FP, 0] ; str
  ADD B, FP, 4
  ST [B, 1], A ; str
  ADD A, FP, 4
  JMP .L1
.L1:
  MOV SP, FP
  ADD SP, 9
  POP B, FP
  RET
charToken:
  PUSH B, FP
  SUB SP, 6
  MOV FP, SP
  ST.B [FP, 0], A
  MOV A, 0
  ADD B, FP, 1
  ST.B [B, 0], A ; type
  LD.B A, [FP, 0] ; c
  ADD B, FP, 1
  ST.B [B, 1], A ; chr
  ADD A, FP, 1
  JMP .L2
.L2:
  MOV SP, FP
  ADD SP, 6
  POP B, FP
  RET
printToken:
  PUSH LR, B, C, D, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD C, [FP, 0] ; token
  LD.B C, [C, 0] ; type
  CMP.B C, 2
  JEQ .L5
  CMP.B C, 1
  JEQ .L6
  CMP.B C, 0
  JEQ .L7
  JMP .L4
.L5:
  LDI C, =.S1
  LD D, [FP, 0] ; token
  LD D, [D, 1] ; str
  MOV A, C
  MOV B, D
  CALL printf
  JMP .L4
.L6:
  LDI C, =.S2
  LD D, [FP, 0] ; token
  LD D, [D, 1] ; num
  MOV A, C
  MOV B, D
  CALL printf
  JMP .L4
.L7:
  LDI C, =.S3
  LD D, [FP, 0] ; token
  LD.B D, [D, 1] ; chr
  MOV A, C
  MOV.B B, D
  CALL printf
.L4:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, D, FP
main:
  PUSH LR, B, C, D, FP
  SUB SP, 15
  MOV FP, SP
  MOV.B B, 'c'
  MOV.B A, B
  CALL charToken
  MOV B, A
  ADD C, FP, 0
  LD.B D, [B, 0]
  ST.B [C, 0], D
  LD D, [B, 1]
  ST [C, 1], D
  ADD B, FP, 0
  MOV A, B
  CALL printToken
  MOV B, 5
  MOV A, B
  CALL intToken
  MOV B, A
  ADD C, FP, 5
  LD.B D, [B, 0]
  ST.B [C, 0], D
  LD D, [B, 1]
  ST [C, 1], D
  ADD B, FP, 5
  MOV A, B
  CALL printToken
  LDI B, =.S4
  MOV A, B
  CALL strToken
  MOV B, A
  ADD C, FP, 10
  LD.B D, [B, 0]
  ST.B [C, 0], D
  LD D, [B, 1]
  ST [C, 1], D
  ADD B, FP, 10
  MOV A, B
  CALL printToken
.L8:
  MOV A, B
  MOV SP, FP
  ADD SP, 15
  POP PC, B, C, D, FP