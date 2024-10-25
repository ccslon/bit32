.S0: "Hello global*\n\0"
gptr: word .S0
garr:
  byte 'H'
  byte 'e'
  byte 'l'
  byte 'l'
  byte 'o'
  byte ' '
  byte 'g'
  byte 'l'
  byte 'o'
  byte 'b'
  byte 'a'
  byte 'l'
  byte '['
  byte ']'
  byte '\n'
  byte '\0'
c: byte 'c'
.S1: "Hello stack*\n\0"
.S2: "Hello cstrings!\n\0"
main:
  PUSH LR, B, C, FP
  SUB SP, 19
  MOV FP, SP
  LDI B, =.S1
  ST [FP, 0], B ; ptr
  ADD B, FP, 4
  MOV.B C, 'H'
  ST.B [B, 0], C
  MOV.B C, 'e'
  ST.B [B, 1], C
  MOV.B C, 'l'
  ST.B [B, 2], C
  MOV.B C, 'l'
  ST.B [B, 3], C
  MOV.B C, 'o'
  ST.B [B, 4], C
  MOV.B C, ' '
  ST.B [B, 5], C
  MOV.B C, 's'
  ST.B [B, 6], C
  MOV.B C, 't'
  ST.B [B, 7], C
  MOV.B C, 'a'
  ST.B [B, 8], C
  MOV.B C, 'c'
  ST.B [B, 9], C
  MOV.B C, 'k'
  ST.B [B, 10], C
  MOV.B C, '['
  ST.B [B, 11], C
  MOV.B C, ']'
  ST.B [B, 12], C
  MOV.B C, '\n'
  ST.B [B, 13], C
  MOV.B C, '\0'
  ST.B [B, 14], C
  LDI B, =.S2
  MOV A, B
  CALL print
  LDI B, =gptr
  LD B, [B]
  MOV A, B
  CALL print
  LDI B, =garr
  MOV A, B
  CALL print
  LD B, [FP, 0] ; ptr
  MOV A, B
  CALL print
  ADD B, FP, 4
  MOV A, B
  CALL print
.L0:
  MOV A, B
  MOV SP, FP
  ADD SP, 19
  POP PC, B, C, FP