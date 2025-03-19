foo:
  PUSH LR
  SUB SP, 12
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; a
  CMP A, 0
  JEQ .L1
  LD A, [SP, 4] ; b
  CMP A, 0
  JEQ .L1
  MOV A, 1
  JMP .L2
.L1:
  MOV A, 0
.L2:
  ST [SP, 8], A ; n
.L3:
  CALL baz
  LD A, [SP, 0] ; a
  CMP A, 0
  JEQ .L5
  LD A, [SP, 4] ; b
  CMP A, 0
  JNE .L3
.L5:
.L4:
  LD A, [SP, 0] ; a
  CMP A, 0
  JEQ .L6
  LD A, [SP, 4] ; b
  CMP A, 0
  JEQ .L6
  MOV A, 100
  JMP .L0
.L6:
.L0:
  ADD SP, 12
  POP PC
bar:
  PUSH LR
  SUB SP, 12
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; a
  CMP A, 0
  JNE .L8
  LD A, [SP, 4] ; b
  CMP A, 0
  JEQ .L9
.L8:
  MOV A, 1
  JMP .L10
.L9:
  MOV A, 0
.L10:
  ST [SP, 8], A ; n
.L11:
  CALL baz
  LD A, [SP, 0] ; a
  CMP A, 0
  JNE .L11
  LD A, [SP, 4] ; b
  CMP A, 0
  JNE .L11
.L12:
  LD A, [SP, 0] ; a
  CMP A, 0
  JNE .L14
  LD A, [SP, 4] ; b
  CMP A, 0
  JEQ .L13
.L14:
  MOV A, 100
  JMP .L7
.L13:
.L7:
  ADD SP, 12
  POP PC