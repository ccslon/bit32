foo:
  .byte 1
  .half 2
  .word 3
globs:
  .word 1
  .word 2
  .word 3
.S0: "Colin\0"
.S1: "Mom\0"
owners:
  .word .S0
  .byte 34
  .word .S1
  .byte 21
cats: .space 27
.S2: "Cats Ya!\0"
name: .word .S2
num: .word 69
lol: .word 420
lmao: .space 4
.S3: "Cloud\0"
print_cat:
  PUSH   B
  SUB    SP, 24
  ST     [SP, 0], A ; cat
  LDI    A, =name
  LD     A, [A]
  ST     [SP, 4], A ; store
  LDI    A, =num
  LD     A, [A]
  ST     [SP, 8], A ; n
  LD     A, [SP, 0] ; cat
  LD     A, [A, 0] ; .name
  ST     [SP, 12], A ; mycat
  LD     A, [SP, 0] ; cat
  LD.B   A, [A, 4] ; .age
  ST     [SP, 16], A ; age
  LD     A, [SP, 0] ; cat
  LD     A, [A, 5] ; .owner
  LD     A, [A, 0] ; .name
  ST     [SP, 20], A ; owner
  LDI    A, 420
  LDI    B, =num
  ST     [B], A
  ADD    SP, 24
  POP    B
  RET
main:
  PUSH   B, LR
  SUB    SP, 4
  LDI    A, =cats
  ADD    A, 18
  ST     [SP, 0], A ; cat1
  LDI    A, =.S3
  LD     B, [SP, 0] ; cat1
  ST     [B, 0], A ; .name
  MOV    A, 10
  LD     B, [SP, 0] ; cat1
  ST.B   [B, 4], A ; .age
  LDI    A, =owners
  ADD    A, 0
  LD     B, [SP, 0] ; cat1
  ST     [B, 5], A ; .owner
  LD     A, [SP, 0] ; cat1
  CALL   print_cat
  MOV    B, 0
  JMP    .L0
.L0:
  MOV    A, B
  ADD    SP, 4
  POP    B, PC