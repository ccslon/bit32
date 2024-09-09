.S0: "Sam\0"
.S1: "Pippin\0"
.S2: "Colin\0"
.S3: "Cloud\0"
.S4: "Nick\0"
.S5: "Chuck\0"
stack_int:
  PUSH B, C, FP
  SUB SP, 51
  MOV FP, SP
  ADD A, FP, 0
  MOV B, 1
  LD [A, 0], B
  MOV B, 2
  LD [A, 4], B
  MOV B, 3
  LD [A, 8], B
  ADD A, FP, 12
  ADD B, A, 0
  MOV C, 1
  LD [B, 0], C
  MOV C, 2
  LD [B, 4], C
  MOV C, 3
  LD [B, 8], C
  ADD B, A, 12
  MOV C, 4
  LD [B, 0], C
  MOV C, 5
  LD [B, 4], C
  MOV C, 6
  LD [B, 8], C
  ADD B, A, 24
  MOV C, 7
  LD [B, 0], C
  MOV C, 8
  LD [B, 4], C
  MOV C, 9
  LD [B, 8], C
  ADD A, FP, 48
  MOV.B B, 'a'
  LD.B [A, 0], B
  MOV.B B, 'b'
  LD.B [A, 1], B
  MOV.B B, 'c'
  LD.B [A, 2], B
.L0:
  MOV SP, FP
  ADD SP, 51
  POP B, C, FP
  RET
stack_cat:
  PUSH A, B, FP
  SUB SP, 5
  MOV FP, SP
  ADD A, FP, 0
  LD B, =.S0
  LD [A, 0], B
  MOV B, 10
  LD.B [A, 4], B
  MOV SP, FP
  ADD SP, 5
  POP A, B, FP
  RET
list_cat:
  PUSH A, B, C, FP
  SUB SP, 10
  MOV FP, SP
  ADD A, FP, 0
  ADD B, A, 0
  LD C, =.S0
  LD [B, 0], C
  MOV C, 10
  LD.B [B, 4], C
  ADD B, A, 5
  LD C, =.S1
  LD [B, 0], C
  MOV C, 6
  LD.B [B, 4], C
  MOV SP, FP
  ADD SP, 10
  POP A, B, C, FP
  RET
stack_person:
  PUSH A, B, C, FP
  SUB SP, 10
  MOV FP, SP
  ADD A, FP, 0
  LD B, =.S2
  LD [A, 0], B
  MOV B, 27
  LD.B [A, 4], B
  ADD B, A, 5
  LD C, =.S3
  LD [B, 0], C
  MOV C, 15
  LD.B [B, 4], C
  MOV SP, FP
  ADD SP, 10
  POP A, B, C, FP
  RET
list_person:
  PUSH A, B, C, D, FP
  SUB SP, 20
  MOV FP, SP
  ADD A, FP, 0
  ADD B, A, 0
  LD C, =.S2
  LD [B, 0], C
  MOV C, 27
  LD.B [B, 4], C
  ADD C, B, 5
  LD D, =.S3
  LD [C, 0], D
  MOV D, 15
  LD.B [C, 4], D
  ADD B, A, 10
  LD C, =.S4
  LD [B, 0], C
  MOV C, 24
  LD.B [B, 4], C
  ADD C, B, 5
  LD D, =.S5
  LD [C, 0], D
  MOV D, 15
  LD.B [C, 4], D
  MOV SP, FP
  ADD SP, 20
  POP A, B, C, D, FP
  RET