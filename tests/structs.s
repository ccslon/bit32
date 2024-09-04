.S0: "Cloud\0"
.S1: "Colin\0"
.S2: "ccslon@gmail.com\0"
stack_cat:
  PUSH A, B, FP
  SUB SP, 18
  MOV FP, SP
  MOV A, 10
  ADD B, FP, 0
  LD.B [B, 4], A ; age
  LD A, =.S0
  ADD B, FP, 0
  LD [B, 0], A ; name
  LD A, =.S1
  ADD B, FP, 0
  ADD B, 5
  LD [B, 0], A ; name
  LD A, =.S2
  ADD B, FP, 0
  ADD B, 5
  LD [B, 4], A ; email
  ADD A, FP, 0
  LD.B A, [A, 4] ; age
  LD.B [FP, 13], A ; age
  ADD A, FP, 0
  ADD A, 5
  LD A, [A, 0] ; name
  LD [FP, 14], A ; name
  MOV SP, FP
  ADD SP, 18
  POP A, B, FP
  RET
heap_cat:
  PUSH B, FP
  SUB SP, 9
  MOV FP, SP
  LD [FP, 0], A
  LD A, =.S0
  LD B, [FP, 0] ; cat
  LD [B, 0], A ; name
  MOV A, 15
  LD B, [FP, 0] ; cat
  LD.B [B, 4], A ; age
  LD A, =.S1
  LD B, [FP, 0] ; cat
  ADD B, 5
  LD [B, 0], A ; name
  LD A, =.S2
  LD B, [FP, 0] ; cat
  ADD B, 5
  LD [B, 4], A ; email
  LD A, [FP, 0] ; cat
  LD.B A, [A, 4] ; age
  LD.B [FP, 4], A ; age
  LD A, [FP, 0] ; cat
  ADD A, 5
  LD A, [A, 0] ; name
  LD [FP, 5], A ; name
  MOV SP, FP
  ADD SP, 9
  POP B, FP
  RET