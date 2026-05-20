foo:
  PUSH   LR
  SUB    SP, 12
  ST     [SP, 0], A ; a
  ST     [SP, 4], B ; b
  LD     A, [SP, 0] ; a
  CMP    A, 0
  JEQ    .L1
  LD     A, [SP, 4] ; b
  CMP    A, 0
.L1:
  MOVNE  A, 1
  MOVEQ  A, 0
  ST     [SP, 8], A ; n
.L2:
  CALL   baz
  LD     A, [SP, 0] ; a
  CMP    A, 0
  JEQ    .L4
  LD     A, [SP, 4] ; b
  CMP    A, 0
  JNE    .L2
.L4:
.L3:
  LD     A, [SP, 0] ; a
  CMP    A, 0
  JEQ    .L5
  LD     A, [SP, 4] ; b
  CMP    A, 0
  JEQ    .L5
  MOV    A, 100
.L5:
.L0:
  ADD    SP, 12
  POP    PC
bar:
  PUSH   LR
  SUB    SP, 12
  ST     [SP, 0], A ; a
  ST     [SP, 4], B ; b
  LD     A, [SP, 0] ; a
  CMP    A, 0
  JNE    .L7
  LD     A, [SP, 4] ; b
  CMP    A, 0
.L7:
  MOVNE  A, 1
  MOVEQ  A, 0
  ST     [SP, 8], A ; n
.L8:
  CALL   baz
  LD     A, [SP, 0] ; a
  CMP    A, 0
  JNE    .L8
  LD     A, [SP, 4] ; b
  CMP    A, 0
  JNE    .L8
.L9:
  LD     A, [SP, 0] ; a
  CMP    A, 0
  JNE    .L11
  LD     A, [SP, 4] ; b
  CMP    A, 0
  JEQ    .L10
.L11:
  MOV    A, 100
.L10:
.L6:
  ADD    SP, 12
  POP    PC
no:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; a
  CMP    A, 0
  MOVEQ  A, 1
  MOVNE  A, 0
  ST     [SP, 4], A ; n
.L13:
  CALL   baz
  LD     A, [SP, 0] ; a
  CMP    A, 0
  JEQ    .L13
.L14:
  LD     A, [SP, 0] ; a
  CMP    A, 0
  JNE    .L15
  MOV    A, 100
.L15:
.L12:
  ADD    SP, 8
  POP    PC