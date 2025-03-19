.S0: "%u\n\0"
.S1: "(STR, \"%s\")\0"
.S2: "(NUM, %d)\0"
.S3: "(CHAR, '%c')\0"
.S4: "Hello!\0"
func1:
  PUSH A, B, LR
  SUB SP, 4
  MOV A, 127
  ADD B, SP, 0
  ADD B, 0
  ST.B [B], A
  MOV A, 0
  ADD B, SP, 0
  ADD B, 1
  ST.B [B], A
  MOV A, 0
  ADD B, SP, 0
  ADD B, 2
  ST.B [B], A
  MOV A, 1
  ADD B, SP, 0
  ADD B, 3
  ST.B [B], A
  LDI A, =.S0
  LD B, [SP, 0] ; i
  CALL printf
  ADD SP, 4
  POP A, B, PC
intToken:
  PUSH B
  SUB SP, 9
  ST [SP, 0], A
  MOV A, 1
  ADD B, SP, 4
  ST.B [B, 0], A ; type
  LD A, [SP, 0] ; num
  ADD B, SP, 4
  ST [B, 1], A ; num
  ADD A, SP, 4
  JMP .L0
.L0:
  ADD SP, 9
  POP B
  RET
strToken:
  PUSH B
  SUB SP, 9
  ST [SP, 0], A
  MOV A, 2
  ADD B, SP, 4
  ST.B [B, 0], A ; type
  LD A, [SP, 0] ; str
  ADD B, SP, 4
  ST [B, 1], A ; str
  ADD A, SP, 4
  JMP .L1
.L1:
  ADD SP, 9
  POP B
  RET
charToken:
  PUSH B
  SUB SP, 6
  ST.B [SP, 0], A
  MOV A, 0
  ADD B, SP, 1
  ST.B [B, 0], A ; type
  LD.B A, [SP, 0] ; c
  ADD B, SP, 1
  ST.B [B, 1], A ; chr
  ADD A, SP, 1
  JMP .L2
.L2:
  ADD SP, 6
  POP B
  RET
printToken:
  PUSH B, LR
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; token
  LD.B A, [A, 0] ; type
  CMP.B A, 2
  JEQ .L5
  CMP.B A, 1
  JEQ .L6
  CMP.B A, 0
  JEQ .L7
  JMP .L4
.L5:
  LDI A, =.S1
  LD B, [SP, 0] ; token
  LD B, [B, 1] ; str
  CALL printf
  JMP .L4
.L6:
  LDI A, =.S2
  LD B, [SP, 0] ; token
  LD B, [B, 1] ; num
  CALL printf
  JMP .L4
.L7:
  LDI A, =.S3
  LD B, [SP, 0] ; token
  LD.B B, [B, 1] ; chr
  CALL printf
.L4:
  ADD SP, 4
  POP B, PC
main:
  PUSH B, C, LR
  SUB SP, 15
  MOV.B A, 'c'
  CALL charToken
  ADD B, SP, 0
  LD.B C, [A, 0]
  ST.B [B, 0], C
  LD C, [A, 1]
  ST [B, 1], C
  ADD A, SP, 0
  CALL printToken
  MOV A, 5
  CALL intToken
  ADD B, SP, 5
  LD.B C, [A, 0]
  ST.B [B, 0], C
  LD C, [A, 1]
  ST [B, 1], C
  ADD A, SP, 5
  CALL printToken
  LDI A, =.S4
  CALL strToken
  ADD B, SP, 10
  LD.B C, [A, 0]
  ST.B [B, 0], C
  LD C, [A, 1]
  ST [B, 1], C
  ADD A, SP, 10
  CALL printToken
.L8:
  ADD SP, 15
  POP B, C, PC