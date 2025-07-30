.S0: "Hello global*\n\0"
gptr: .word .S0
garr: "Hello global[]\n\0"
c: .byte 'c'
.S1: "Hello stack*\n\0"
.S2: "Hello cstrings!\n\0"
main:
  PUSH   B, C, LR
  SUB    SP, 19
  LDI    A, =.S1
  ST     [SP, 0], A ; ptr
  ADD    B, SP, 4 ; arr
  MOV.B  C, 'H'
  ST.B   [B, 0], C
  MOV.B  C, 'e'
  ST.B   [B, 1], C
  MOV.B  C, 'l'
  ST.B   [B, 2], C
  MOV.B  C, 'l'
  ST.B   [B, 3], C
  MOV.B  C, 'o'
  ST.B   [B, 4], C
  MOV.B  C, ' '
  ST.B   [B, 5], C
  MOV.B  C, 's'
  ST.B   [B, 6], C
  MOV.B  C, 't'
  ST.B   [B, 7], C
  MOV.B  C, 'a'
  ST.B   [B, 8], C
  MOV.B  C, 'c'
  ST.B   [B, 9], C
  MOV.B  C, 'k'
  ST.B   [B, 10], C
  MOV.B  C, '['
  ST.B   [B, 11], C
  MOV.B  C, ']'
  ST.B   [B, 12], C
  MOV.B  C, '\n'
  ST.B   [B, 13], C
  MOV.B  C, '\0'
  ST.B   [B, 14], C
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
  POP    B, C, PC