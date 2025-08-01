.S0: "%u\n\0"
.S1: "(STR, \"%s\")\0"
.S2: "(NUM, %d)\0"
.S3: "(CHAR, '%c')\0"
.S4: "Hello!\0"
func1:
  PUSH   A, B, LR
  SUB    SP, 4
  MOV    A, 127
  ST.B   [SP, 0], A ; ip
  MOV    A, 0
  ST.B   [SP, 1], A ; ip
  MOV    A, 0
  ST.B   [SP, 2], A ; ip
  MOV    A, 1
  ST.B   [SP, 3], A ; ip
  LDI    A, =.S0
  LD     B, [SP, 0] ; ip
  CALL   printf
  ADD    SP, 4
  POP    A, B, PC
intToken:
  SUB    SP, 9
  ST     [SP, 0], A ; num
  MOV    A, 1
  ST.B   [SP, 4], A ; token
  LD     A, [SP, 0] ; num
  ST     [SP, 5], A ; token
  ADD    A, SP, 4 ; token
.L0:
  ADD    SP, 9
  RET
strToken:
  SUB    SP, 9
  ST     [SP, 0], A ; str
  MOV    A, 2
  ST.B   [SP, 4], A ; token
  LD     A, [SP, 0] ; str
  ST     [SP, 5], A ; token
  ADD    A, SP, 4 ; token
.L1:
  ADD    SP, 9
  RET
charToken:
  SUB    SP, 6
  ST.B   [SP, 0], A ; c
  MOV    A, 0
  ST.B   [SP, 1], A ; token
  LD.B   A, [SP, 0] ; c
  ST.B   [SP, 2], A ; token
  ADD    A, SP, 1 ; token
.L2:
  ADD    SP, 6
  RET
printToken:
  PUSH   B, LR
  SUB    SP, 4
  ST     [SP, 0], A ; token
  LD     A, [SP, 0] ; token
  LD.B   A, [A, 0] ; .type
  CMP.B  A, 2
  JEQ    .L5
  CMP.B  A, 1
  JEQ    .L6
  CMP.B  A, 0
  JEQ    .L7
  JMP    .L4
.L5:
  LDI    A, =.S1
  LD     B, [SP, 0] ; token
  LD     B, [B, 1] ; .str
  CALL   printf
  JMP    .L4
.L6:
  LDI    A, =.S2
  LD     B, [SP, 0] ; token
  LD     B, [B, 1] ; .num
  CALL   printf
  JMP    .L4
.L7:
  LDI    A, =.S3
  LD     B, [SP, 0] ; token
  LD.B   B, [B, 1] ; .sym
  CALL   printf
.L4:
  ADD    SP, 4
  POP    B, PC
main:
  PUSH   B, C, LR
  SUB    SP, 15
  MOV.B  A, 'c'
  CALL   charToken
  ADD    B, SP, 0 ; t0
  LD.B   C, [A, 0]
  ST.B   [B, 0], C
  LD     C, [A, 1]
  ST     [B, 1], C
  ADD    A, SP, 0 ; t0
  CALL   printToken
  MOV    A, 5
  CALL   intToken
  ADD    B, SP, 5 ; t1
  LD.B   C, [A, 0]
  ST.B   [B, 0], C
  LD     C, [A, 1]
  ST     [B, 1], C
  ADD    A, SP, 5 ; t1
  CALL   printToken
  LDI    A, =.S4
  CALL   strToken
  ADD    B, SP, 10 ; t2
  LD.B   C, [A, 0]
  ST.B   [B, 0], C
  LD     C, [A, 1]
  ST     [B, 1], C
  ADD    A, SP, 10 ; t2
  CALL   printToken
.L8:
  ADD    SP, 15
  POP    B, C, PC
getp1:
  SUB    SP, 4
  ST     [SP, 0], A ; s
  LD     A, [SP, 0] ; s
  LD.H   A, [A]
.L9:
  ADD    SP, 4
  RET
getp2:
  SUB    SP, 4
  ST     [SP, 0], A ; s
  LD     A, [SP, 0] ; s
  LD.H   A, [A, 0] ; .num
.L10:
  ADD    SP, 4
  RET
gets1:
  SUB    SP, 2
  LD.H   A, [SP, 0] ; s
.L11:
  ADD    SP, 2
  RET
gets2:
  SUB    SP, 2
  LD.H   A, [SP, 0] ; box
.L12:
  ADD    SP, 2
  RET
geta1:
  SUB    SP, 10
  LD.H   A, [SP, 6] ; foo
.L13:
  ADD    SP, 10
  RET
geta2:
  SUB    SP, 10
  LD.H   A, [SP, 6] ; boxes
.L14:
  ADD    SP, 10
  RET
getp3:
  SUB    SP, 20
  LD     A, [SP, 12] ; foo
  LD.H   A, [A]
.L15:
  ADD    SP, 20
  RET
getp:
  SUB    SP, 20
  LD     A, [SP, 12] ; boxes
  LD.H   A, [A, 0] ; .num
.L16:
  ADD    SP, 20
  RET