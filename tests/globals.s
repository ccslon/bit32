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
lmao: .word 0
.S3: "Cloud\0"
print_cat:
  PUSH   B, C
  SUB    SP, 24
  ST     [SP, 0], A ; cat
  LDI    A, =name
  LD     A, [A]
  ST     [SP, 4], A ; store
  LDI    C, =num
  LD     A, [C]
  ST     [SP, 8], A ; n
  LD     B, [SP, 0] ; cat
  LD     A, [B, 0] ; .name
  ST     [SP, 12], A ; mycat
  LD.B   A, [B, 4] ; .age
  ST     [SP, 16], A ; age
  LD     A, [B, 5] ; .owner
  LD     A, [A, 0] ; .name
  ST     [SP, 20], A ; owner
  LDI    A, 420
  ST     [C], A
  ADD    SP, 24
  POP    B, C
  RET
main:
  PUSH   B, LR
  SUB    SP, 4
  LDI    A, =cats
  ADD    A, 18
  ST     [SP, 0], A ; cat1
  LDI    B, =.S3
  LD     A, [SP, 0] ; cat1
  ST     [A, 0], B ; .name
  MOV    B, 10
  ST.B   [A, 4], B ; .age
  LDI    B, =owners
  ADD    B, 0
  ST     [A, 5], B ; .owner
  CALL   print_cat
  MOV    A, 0
.L0:
  ADD    SP, 4
  POP    B, PC