.S0: "Cloud\0"
.S1: "Colin\0"
.S2: "ccslon@gmail.com\0"
stack_cat:
  PUSH A, B, FP
  SUB SP, 18
  MOV FP, SP
  MOV A, 10
  ADD B, FP, 0
  ST.B [B, 4], A ; age
  LDI A, =.S0
  ADD B, FP, 0
  ST [B, 0], A ; name
  LDI A, =.S1
  ADD B, FP, 0
  ADD B, 5
  ST [B, 0], A ; name
  LDI A, =.S2
  ADD B, FP, 0
  ADD B, 5
  ST [B, 4], A ; email
  ADD A, FP, 0
  LD.B A, [A, 4] ; age
  ST.B [FP, 13], A ; age
  ADD A, FP, 0
  ADD A, 5
  LD A, [A, 0] ; name
  ST [FP, 14], A ; name
  MOV SP, FP
  ADD SP, 18
  POP A, B, FP
  RET
heap_cat:
  PUSH B, FP
  SUB SP, 9
  MOV FP, SP
  ST [FP, 0], A
  LDI A, =.S0
  LD B, [FP, 0] ; cat
  ST [B, 0], A ; name
  MOV A, 15
  LD B, [FP, 0] ; cat
  ST.B [B, 4], A ; age
  LDI A, =.S1
  LD B, [FP, 0] ; cat
  ADD B, 5
  ST [B, 0], A ; name
  LDI A, =.S2
  LD B, [FP, 0] ; cat
  ADD B, 5
  ST [B, 4], A ; email
  LD A, [FP, 0] ; cat
  LD.B A, [A, 4] ; age
  ST.B [FP, 4], A ; age
  LD A, [FP, 0] ; cat
  ADD A, 5
  LD A, [A, 0] ; name
  ST [FP, 5], A ; name
  MOV SP, FP
  ADD SP, 9
  POP B, FP
  RET