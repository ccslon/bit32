foo1:
  PUSH LR
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; n
  CMP A, 1
  JNE .L0
  MOV A, 100
  CALL bar
.L0:
  ADD SP, 4
  POP PC
foo2:
  PUSH LR
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; n
  CMP A, 1
  JNE .L2
  MOV A, 100
  CALL bar
  JMP .L1
.L2:
  LD A, [SP, 0] ; n
  CMP A, 100
  JLE .L1
  MVN A, 1
  CALL bar
.L1:
  ADD SP, 4
  POP PC
foo2_5:
  PUSH LR
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; n
  CMP A, 1
  JNE .L4
  MOV A, 100
  CALL bar
  JMP .L3
.L4:
  LD A, [SP, 0] ; n
  CMP A, 100
  JLE .L5
  MVN A, 1
  CALL bar
.L5:
.L3:
  ADD SP, 4
  POP PC
foo3:
  PUSH LR
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; n
  CMP A, 1
  JNE .L7
  MOV A, 100
  CALL bar
  JMP .L6
.L7:
  MOV A, 0
  CALL bar
.L6:
  ADD SP, 4
  POP PC
foo4:
  PUSH LR
  SUB SP, 4
  ST [SP, 0], A
  LD A, [SP, 0] ; n
  CMP A, 1
  JNE .L9
  MOV A, 100
  CALL bar
  JMP .L8
.L9:
  LD A, [SP, 0] ; n
  CMP A, 100
  JLE .L10
  MVN A, 1
  CALL bar
  JMP .L8
.L10:
  MOV A, 0
  CALL bar
.L8:
  ADD SP, 4
  POP PC