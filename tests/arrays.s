.S0: "Sam\0"
.S1: "Pippin\0"
.S2: "Colin\0"
.S3: "Cloud\0"
.S4: "Nick\0"
.S5: "Chuck\0"
stack_int:
  PUSH   B, C
  SUB    SP, 51
  ADD    B, SP, 0 ; ints
  MOV    A, 1
  ST     [B, 0], A
  MOV    A, 2
  ST     [B, 4], A
  MOV    A, 3
  ST     [B, 8], A
  ADD    C, SP, 12 ; ints2d
  ADD    B, C, 0
  MOV    A, 1
  ST     [B, 0], A
  MOV    A, 2
  ST     [B, 4], A
  MOV    A, 3
  ST     [B, 8], A
  ADD    B, C, 12
  MOV    A, 4
  ST     [B, 0], A
  MOV    A, 5
  ST     [B, 4], A
  MOV    A, 6
  ST     [B, 8], A
  ADD    B, C, 24
  MOV    A, 7
  ST     [B, 0], A
  MOV    A, 8
  ST     [B, 4], A
  MOV    A, 9
  ST     [B, 8], A
  ADD    B, SP, 48 ; chars
  MOV.B  A, 'a'
  ST.B   [B, 0], A
  MOV.B  A, 'b'
  ST.B   [B, 1], A
  MOV.B  A, 'c'
  ST.B   [B, 2], A
.L0:
  ADD    SP, 51
  POP    B, C
  RET
stack_cat:
  PUSH   A, B
  SUB    SP, 5
  ADD    B, SP, 0 ; cat
  LDI    A, =.S0
  ST     [B, 0], A
  MOV    A, 10
  ST.B   [B, 4], A
  ADD    SP, 5
  POP    A, B
  RET
list_cat:
  PUSH   A, B, C
  SUB    SP, 10
  ADD    B, SP, 0 ; cats
  ADD    C, B, 0
  LDI    A, =.S0
  ST     [C, 0], A
  MOV    A, 10
  ST.B   [C, 4], A
  ADD    B, 5
  LDI    A, =.S1
  ST     [B, 0], A
  MOV    A, 6
  ST.B   [B, 4], A
  ADD    SP, 10
  POP    A, B, C
  RET
stack_person:
  PUSH   A, B
  SUB    SP, 10
  ADD    B, SP, 0 ; me
  LDI    A, =.S2
  ST     [B, 0], A
  MOV    A, 27
  ST.B   [B, 4], A
  ADD    B, 5
  LDI    A, =.S3
  ST     [B, 0], A
  MOV    A, 15
  ST.B   [B, 4], A
  ADD    SP, 10
  POP    A, B
  RET
list_person:
  PUSH   A, B, C
  SUB    SP, 20
  ADD    C, SP, 0 ; people
  ADD    B, C, 0
  LDI    A, =.S2
  ST     [B, 0], A
  MOV    A, 27
  ST.B   [B, 4], A
  ADD    B, 5
  LDI    A, =.S3
  ST     [B, 0], A
  MOV    A, 15
  ST.B   [B, 4], A
  ADD    B, C, 10
  LDI    A, =.S4
  ST     [B, 0], A
  MOV    A, 24
  ST.B   [B, 4], A
  ADD    B, 5
  LDI    A, =.S5
  ST     [B, 0], A
  MOV    A, 15
  ST.B   [B, 4], A
  ADD    SP, 20
  POP    A, B, C
  RET