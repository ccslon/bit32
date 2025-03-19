.S0: "Cloud\0"
.S1: "Colin\0"
.S2: "ccslon@gmail.com\0"
stack_cat:
  PUSH A, B
  SUB SP, 18
  MOV A, 10
  ADD B, SP, 0
  ST.B [B, 4], A ; age
  LDI A, =.S0
  ADD B, SP, 0
  ST [B, 0], A ; name
  LDI A, =.S1
  ADD B, SP, 0
  ADD B, 5
  ST [B, 0], A ; name
  LDI A, =.S2
  ADD B, SP, 0
  ADD B, 5
  ST [B, 4], A ; email
  ADD A, SP, 0
  LD.B A, [A, 4] ; age
  ST.B [SP, 13], A ; age
  ADD A, SP, 0
  ADD A, 5
  LD A, [A, 0] ; name
  ST [SP, 14], A ; name
  ADD SP, 18
  POP A, B
  RET
heap_cat:
  PUSH B
  SUB SP, 9
  ST [SP, 0], A
  LDI A, =.S0
  LD B, [SP, 0] ; cat
  ST [B, 0], A ; name
  MOV A, 15
  LD B, [SP, 0] ; cat
  ST.B [B, 4], A ; age
  LDI A, =.S1
  LD B, [SP, 0] ; cat
  ADD B, 5
  ST [B, 0], A ; name
  LDI A, =.S2
  LD B, [SP, 0] ; cat
  ADD B, 5
  ST [B, 4], A ; email
  LD A, [SP, 0] ; cat
  LD.B A, [A, 4] ; age
  ST.B [SP, 4], A ; age
  LD A, [SP, 0] ; cat
  ADD A, 5
  LD A, [A, 0] ; name
  ST [SP, 5], A ; name
  ADD SP, 9
  POP B
  RET