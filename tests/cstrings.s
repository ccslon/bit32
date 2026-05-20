.S0: "Hello global*\n\0"
gptr: .word .S0
garr: "Hello global[]\n\0"
c: .byte 'c'
.S1: "Hello stack*\n\0"
.S2: "Hello cstrings!\n\0"
main:
  PUSH   B, LR
  SUB    SP, 19
  LDI    A, =.S1
  ST     [SP, 0], A ; ptr
  ADD    B, SP, 4 ; arr
  MOV.B  A, 'H'
  ST.B   [B, 0], A
  MOV.B  A, 'e'
  ST.B   [B, 1], A
  MOV.B  A, 'l'
  ST.B   [B, 2], A
  MOV.B  A, 'l'
  ST.B   [B, 3], A
  MOV.B  A, 'o'
  ST.B   [B, 4], A
  MOV.B  A, ' '
  ST.B   [B, 5], A
  MOV.B  A, 's'
  ST.B   [B, 6], A
  MOV.B  A, 't'
  ST.B   [B, 7], A
  MOV.B  A, 'a'
  ST.B   [B, 8], A
  MOV.B  A, 'c'
  ST.B   [B, 9], A
  MOV.B  A, 'k'
  ST.B   [B, 10], A
  MOV.B  A, '['
  ST.B   [B, 11], A
  MOV.B  A, ']'
  ST.B   [B, 12], A
  MOV.B  A, '\n'
  ST.B   [B, 13], A
  MOV.B  A, '\0'
  ST.B   [B, 14], A
  LDI    A, =.S2
  CALL   print
  LDI    A, =gptr
  LD     A, [A]
  CALL   print
  LDI    A, =garr
  CALL   print
  LD     A, [SP, 0] ; ptr
  CALL   print
  ADD    A, SP, 4 ; arr
  CALL   print
.L0:
  ADD    SP, 19
  POP    B, PC