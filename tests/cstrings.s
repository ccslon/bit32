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
  LD B, =.S1
  LD [FP, 0], B ; ptr
  ADD B, FP, 4
  MOV.B C, 'H'
  LD.B [B, 0], C
  MOV.B C, 'e'
  LD.B [B, 1], C
  MOV.B C, 'l'
  LD.B [B, 2], C
  MOV.B C, 'l'
  LD.B [B, 3], C
  MOV.B C, 'o'
  LD.B [B, 4], C
  MOV.B C, ' '
  LD.B [B, 5], C
  MOV.B C, 's'
  LD.B [B, 6], C
  MOV.B C, 't'
  LD.B [B, 7], C
  MOV.B C, 'a'
  LD.B [B, 8], C
  MOV.B C, 'c'
  LD.B [B, 9], C
  MOV.B C, 'k'
  LD.B [B, 10], C
  MOV.B C, '['
  LD.B [B, 11], C
  MOV.B C, ']'
  LD.B [B, 12], C
  MOV.B C, '\n'
  LD.B [B, 13], C
  MOV.B C, '\0'
  LD.B [B, 14], C
  LD B, =.S2
  MOV A, B
  CALL print
  LD B, =gptr
  LD B, [B]
  MOV A, B
  CALL print
  LD B, =garr
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