foo:
  byte 1
  half 2
  word 3
globs:
  word 1
  word 2
  word 3
.S0: "Colin\0"
.S1: "Mom\0"
owners:
  word .S0
  byte 34
  word .S1
  byte 21
cats: space 27
.S2: "Cats Ya!\0"
name: word .S2
num: word 69
.S3: "Cloud\0"
print_cat:
  PUSH FP
  SUB SP, 24
  MOV FP, SP
  ST [FP, 0], A
  LDI A, =name
  LD A, [A]
  ST [FP, 4], A ; store
  LDI A, =num
  LD A, [A]
  ST [FP, 8], A ; n
  LD A, [FP, 0] ; cat
  LD A, [A, 0] ; name
  ST [FP, 12], A ; mycat
  LD A, [FP, 0] ; cat
  LD.B A, [A, 4] ; age
  ST [FP, 16], A ; age
  LD A, [FP, 0] ; cat
  LD A, [A, 5] ; owner
  LD A, [A, 0] ; name
  ST [FP, 20], A ; owner
  MOV SP, FP
  ADD SP, 24
  POP FP
  RET
main:
  PUSH LR, B, C, FP
  SUB SP, 4
  MOV FP, SP
  LDI B, =cats
  MOV C, 0
  MUL C, 9
  ADD B, C
  ST [FP, 0], B ; cat1
  LDI B, =.S3
  LD C, [FP, 0] ; cat1
  ST [C, 0], B ; name
  MOV B, 10
  LD C, [FP, 0] ; cat1
  ST.B [C, 4], B ; age
  LDI B, =owners
  MOV C, 0
  MUL C, 5
  ADD B, C
  LD C, [FP, 0] ; cat1
  ST [C, 5], B ; owner
  LD B, [FP, 0] ; cat1
  MOV A, B
  CALL print_cat
  MOV B, 0
  JMP .L0
.L0:
  MOV A, B
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, FP