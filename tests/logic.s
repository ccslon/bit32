foo:
  PUSH LR, FP
  SUB SP, 12
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
  LD A, [FP, 0] ; a
  CMP A, 0
  JEQ .L1
  LD A, [FP, 4] ; b
  CMP A, 0
  JEQ .L1
  MOV A, 1
  JMP .L2
.L1:
  MOV A, 0
.L2:
  LD [FP, 8], A ; n
.L3:
  CALL baz
  LD A, [FP, 0] ; a
  CMP A, 0
  JEQ .L5
  LD A, [FP, 4] ; b
  CMP A, 0
  JNE .L3
.L5:
.L4:
  LD A, [FP, 0] ; a
  CMP A, 0
  JEQ .L6
  LD A, [FP, 4] ; b
  CMP A, 0
  JEQ .L6
  MOV A, 100
  JMP .L0
.L6:
.L0:
  MOV SP, FP
  ADD SP, 12
  POP PC, FP
bar:
  PUSH LR, FP
  SUB SP, 12
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
  LD A, [FP, 0] ; a
  CMP A, 0
  JNE .L8
  LD A, [FP, 4] ; b
  CMP A, 0
  JEQ .L9
.L8:
  MOV A, 1
  JMP .L10
.L9:
  MOV A, 0
.L10:
  LD [FP, 8], A ; n
.L11:
  CALL baz
  LD A, [FP, 0] ; a
  CMP A, 0
  JNE .L11
  LD A, [FP, 4] ; b
  CMP A, 0
  JNE .L11
.L12:
  LD A, [FP, 0] ; a
  CMP A, 0
  JNE .L14
  LD A, [FP, 4] ; b
  CMP A, 0
  JEQ .L13
.L14:
  MOV A, 100
  JMP .L7
.L13:
.L7:
  MOV SP, FP
  ADD SP, 12
  POP PC, FP