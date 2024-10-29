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
  ST [A, 0], B
  MOV B, 2
  ST [A, 4], B
  MOV B, 3
  ST [A, 8], B
  ADD A, FP, 12
  ADD B, A, 0
  MOV C, 1
  ST [B, 0], C
  MOV C, 2
  ST [B, 4], C
  MOV C, 3
  ST [B, 8], C
  ADD B, A, 12
  MOV C, 4
  ST [B, 0], C
  MOV C, 5
  ST [B, 4], C
  MOV C, 6
  ST [B, 8], C
  ADD B, A, 24
  MOV C, 7
  ST [B, 0], C
  MOV C, 8
  ST [B, 4], C
  MOV C, 9
  ST [B, 8], C
  ADD A, FP, 48
  MOV.B B, 'a'
  ST.B [A, 0], B
  MOV.B B, 'b'
  ST.B [A, 1], B
  MOV.B B, 'c'
  ST.B [A, 2], B
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
  LDI B, =.S0
  ST [A, 0], B
  MOV B, 10
  ST.B [A, 4], B
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
  LDI C, =.S0
  ST [B, 0], C
  MOV C, 10
  ST.B [B, 4], C
  ADD B, A, 5
  LDI C, =.S1
  ST [B, 0], C
  MOV C, 6
  ST.B [B, 4], C
  MOV SP, FP
  ADD SP, 10
  POP A, B, C, FP
  RET
stack_person:
  PUSH A, B, C, FP
  SUB SP, 10
  MOV FP, SP
  ADD A, FP, 0
  LDI B, =.S2
  ST [A, 0], B
  MOV B, 27
  ST.B [A, 4], B
  ADD B, A, 5
  LDI C, =.S3
  ST [B, 0], C
  MOV C, 15
  ST.B [B, 4], C
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
  LDI C, =.S2
  ST [B, 0], C
  MOV C, 27
  ST.B [B, 4], C
  ADD C, B, 5
  LDI D, =.S3
  ST [C, 0], D
  MOV D, 15
  ST.B [C, 4], D
  ADD B, A, 10
  LDI C, =.S4
  ST [B, 0], C
  MOV C, 24
  ST.B [B, 4], C
  ADD C, B, 5
  LDI D, =.S5
  ST [C, 0], D
  MOV D, 15
  ST.B [C, 4], D
  MOV SP, FP
  ADD SP, 20
  POP A, B, C, D, FP
  RET