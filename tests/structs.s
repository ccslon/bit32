.S0: "Cloud\0"
.S1: "Colin\0"
.S2: "ccslon@gmail.com\0"
stack_cat:
  PUSH   A
  SUB    SP, 18
  MOV    A, 10
  ST.B   [SP, 4], A ; cat
  LDI    A, =.S0
  ST     [SP, 0], A ; cat
  LDI    A, =.S1
  ST     [SP, 5], A ; cat
  LDI    A, =.S2
  ST     [SP, 9], A ; cat
  LD.B   A, [SP, 4] ; cat
  ST.B   [SP, 13], A ; age
  LD     A, [SP, 5] ; cat
  ST     [SP, 14], A ; name
  ADD    SP, 18
  POP    A
  RET
heap_cat:
  PUSH   B
  SUB    SP, 9
  ST     [SP, 0], A ; cat
  LDI    A, =.S0
  LD     B, [SP, 0] ; cat
  ST     [B, 0], A ; .name
  MOV    A, 15
  LD     B, [SP, 0] ; cat
  ST.B   [B, 4], A ; .age
  LDI    A, =.S1
  LD     B, [SP, 0] ; cat
  ST     [B, 5], A ; .owner
  LDI    A, =.S2
  LD     B, [SP, 0] ; cat
  ST     [B, 9], A ; .owner
  LD     A, [SP, 0] ; cat
  LD.B   A, [A, 4] ; .age
  ST.B   [SP, 4], A ; age
  LD     A, [SP, 0] ; cat
  LD     A, [A, 5] ; .owner
  ST     [SP, 5], A ; name
  ADD    SP, 9
  POP    B
  RET