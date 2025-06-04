fgetc:
  PUSH B, FP
  SUB SP, 5
  MOV FP, SP
  ST [FP, 0], A
.L1:
  LD A, [FP, 0] ; stream
  LD A, [A, 4] ; read
  LD B, [FP, 0] ; stream
  LD B, [B, 8] ; write
  CMP A, B
  JNE .L2
  JMP .L1
.L2:
  LD A, [FP, 0] ; stream
  LD A, [A, 0] ; buffer
  LD B, [FP, 0] ; stream
  LD B, [B, 4] ; read
  ADD A, B
  LD.B A, [A]
  ST.B [FP, 4], A ; c
  LD A, [FP, 0] ; stream
  LD A, [A, 4] ; read
  ADD A, 1
  LD B, [FP, 0] ; stream
  LD B, [B, 12] ; size
  MOD A, B
  LD B, [FP, 0] ; stream
  ST [B, 4], A ; read
  LD.B A, [FP, 4] ; c
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 5
  POP B, FP
  RET
getchar:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
.L4:
  LDI A, =stdin
  LD A, [A, 4] ; read
  LDI B, =stdin
  LD B, [B, 8] ; write
  CMP A, B
  JNE .L5
  JMP .L4
.L5:
  LDI A, =stdin
  LD A, [A, 0] ; buffer
  LDI B, =stdin
  LD B, [B, 4] ; read
  ADD A, B
  LD.B A, [A]
  ST.B [FP, 0], A ; c
  LDI A, =stdin
  LD A, [A, 4] ; read
  ADD A, 1
  LDI B, =stdin
  LD B, [B, 12] ; size
  MOD A, B
  LDI B, =stdin
  ST [B, 4], A ; read
  LD.B A, [FP, 0] ; c
  JMP .L3
.L3:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
fgets:
  PUSH LR, D, FP
  SUB SP, 17
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD B, [FP, 0] ; s
  ST [FP, 13], B ; cs
.L7:
  LD B, [FP, 4] ; n
  SUB B, 1
  ST [FP, 4], B ; n
  CMP B, 0
  JLS .L8
  LD B, [FP, 8] ; stream
  MOV A, B
  CALL fgetc
  MOV B, A
  ST.B [FP, 12], B ; c
  CMP.B B, 0
  JEQ .L8
  LD.B B, [FP, 12] ; c
  LD C, [FP, 13] ; cs
  ADD D, C, 1
  ST [FP, 13], D ; cs
  ST.B [C], B
  CMP.B B, '\0'
  JNE .L9
  JMP .L8
.L9:
  JMP .L7
.L8:
  LD B, [FP, 0] ; s
  JMP .L6
.L6:
  MOV A, B
  MOV SP, FP
  ADD SP, 17
  POP PC, D, FP
gets:
  PUSH LR, C, D, E, F, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD D, [FP, 0] ; s
  LD E, [FP, 4] ; n
  LDI F, =stdin
  MOV A, D
  MOV B, E
  MOV C, F
  CALL fgets
  MOV D, A
  JMP .L10
.L10:
  MOV A, D
  MOV SP, FP
  ADD SP, 8
  POP PC, C, D, E, F, FP
fputc:
  PUSH C, FP
  SUB SP, 5
  MOV FP, SP
  ST.B [FP, 0], A
  ST [FP, 1], B
  LD.B A, [FP, 0] ; c
  LD B, [FP, 1] ; stream
  LD B, [B, 0] ; buffer
  LD C, [FP, 1] ; stream
  LD C, [C, 8] ; write
  ADD B, C
  ST.B [B], A
  LD A, [FP, 1] ; stream
  LD A, [A, 8] ; write
  ADD A, 1
  LD B, [FP, 1] ; stream
  LD B, [B, 12] ; size
  MOD A, B
  LD B, [FP, 1] ; stream
  ST [B, 8], A ; write
  MOV A, 0
  JMP .L11
.L11:
  MOV SP, FP
  ADD SP, 5
  POP C, FP
  RET
putchar:
  PUSH B, C, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B A, [FP, 0] ; c
  LDI B, =stdout
  LD B, [B, 0] ; buffer
  LDI C, =stdout
  LD C, [C, 8] ; write
  ADD B, C
  ST.B [B], A
  LDI A, =stdout
  LD A, [A, 8] ; write
  ADD A, 1
  LDI B, =stdout
  LD B, [B, 12] ; size
  MOD A, B
  LDI B, =stdout
  ST [B, 8], A ; write
  MOV A, 0
  JMP .L12
.L12:
  MOV SP, FP
  ADD SP, 1
  POP B, C, FP
  RET
fputs:
  PUSH LR, C, D, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
.L14:
  LD C, [FP, 0] ; s
  LD.B C, [C]
  CMP.B C, '\0'
  JEQ .L15
  LD C, [FP, 0] ; s
  LD.B C, [C]
  LD D, [FP, 4] ; stream
  MOV.B A, C
  MOV B, D
  CALL fputc
  LD C, [FP, 0] ; s
  ADD D, C, 1
  ST [FP, 0], D ; s
  JMP .L14
.L15:
  MOV C, 0
  JMP .L13
.L13:
  MOV A, C
  MOV SP, FP
  ADD SP, 8
  POP PC, C, D, FP
puts:
  PUSH LR, B, C, D, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD C, [FP, 0] ; s
  LDI D, =stdout
  MOV A, C
  MOV B, D
  CALL fputs
  MOV.B C, '\n'
  MOV.B A, C
  CALL putchar
  MOV C, 0
  JMP .L16
.L16:
  MOV A, C
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, D, FP
uprint:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  DIV B, 10
  CMP B, 0
  JEQ .L17
  LD B, [FP, 0] ; n
  DIV B, 10
  MOV A, B
  CALL uprint
.L17:
  LD B, [FP, 0] ; n
  MOD B, 10
  ADD B, '0'
  MOV A, B
  CALL putchar
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
dprint:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 0
  JGE .L18
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; n
  NEG B
  ST [FP, 0], B ; n
.L18:
  LD B, [FP, 0] ; n
  MOV A, B
  CALL uprint
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
xprint:
  PUSH LR, C, D, FP
  SUB SP, 5
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD C, [FP, 0] ; n
  DIV C, 16
  CMP C, 0
  JEQ .L19
  LD C, [FP, 0] ; n
  DIV C, 16
  LD.B D, [FP, 4] ; uplo
  MOV A, C
  MOV.B B, D
  CALL xprint
.L19:
  LD C, [FP, 0] ; n
  MOD C, 16
  CMP C, 9
  JLS .L21
  LD C, [FP, 0] ; n
  MOD C, 16
  SUB C, 10
  LD.B D, [FP, 4] ; uplo
  ADD C, D
  MOV A, C
  CALL putchar
  JMP .L20
.L21:
  LD C, [FP, 0] ; n
  MOD C, 16
  ADD C, '0'
  MOV A, C
  CALL putchar
.L20:
  MOV SP, FP
  ADD SP, 5
  POP PC, C, D, FP
fprint:
  PUSH LR, C, FP
  SUB SP, 17
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD B, [FP, 0] ; f
  MOV C, 0
  ITF C, C
  CMPF B, C
  JGE .L22
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; f
  NEGF B
  ST [FP, 0], B ; f
.L22:
  LD B, [FP, 0] ; f
  FTI B, B
  ST [FP, 5], B ; left
  LD B, [FP, 5] ; left
  MOV A, B
  CALL dprint
  MOV.B B, '.'
  MOV.B A, B
  CALL putchar
  MOV B, 1
  ST [FP, 9], B ; p
.L23:
  LD.B B, [FP, 4] ; prec
  CMP B, 0
  JLE .L25
  LD B, [FP, 9] ; p
  MUL B, 10
  ST [FP, 9], B ; p
.L24:
  LD.B B, [FP, 4] ; prec
  SUB.B B, 1
  ST.B [FP, 4], B ; prec
  JMP .L23
.L25:
  LD B, [FP, 0] ; f
  LD C, [FP, 5] ; left
  ITF C, C
  SUBF B, C
  LD C, [FP, 9] ; p
  ITF C, C
  MULF B, C
  FTI B, B
  ST [FP, 13], B ; right
  LD B, [FP, 13] ; right
  MOV A, B
  CALL dprint
  MOV SP, FP
  ADD SP, 17
  POP PC, C, FP
printf:
  PUSH D, C, B, A
  PUSH LR, FP
  SUB SP, 8
  MOV FP, SP
  ADD C, FP, 16
  ADD C, 4
  ST [FP, 0], C ; ap
  LD C, [FP, 16] ; format
  ST [FP, 4], C ; c
.L26:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, 0
  JEQ .L28
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, '%'
  JNE .L30
  LD C, [FP, 4] ; c
  ADD C, 1
  ST [FP, 4], C ; c
  LD.B C, [C]
  CMP.B C, 'u'
  JEQ .L33
  CMP.B C, 'i'
  JEQ .L34
  CMP.B C, 'd'
  JEQ .L35
  CMP.B C, 'x'
  JEQ .L36
  CMP.B C, 'X'
  JEQ .L37
  CMP.B C, 's'
  JEQ .L38
  CMP.B C, 'c'
  JEQ .L39
  JMP .L40
.L33:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL uprint
  JMP .L32
.L34:
.L35:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL dprint
  JMP .L32
.L36:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV.B D, 'a'
  MOV A, C
  MOV.B B, D
  CALL xprint
  JMP .L32
.L37:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV.B D, 'A'
  MOV A, C
  MOV.B B, D
  CALL xprint
  JMP .L32
.L38:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL printf
  JMP .L32
.L39:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV.B A, C
  CALL putchar
  JMP .L32
.L40:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
.L32:
  JMP .L29
.L30:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
.L29:
.L27:
  LD C, [FP, 4] ; c
  ADD D, C, 1
  ST [FP, 4], D ; c
  JMP .L26
.L28:
  MOV C, 0
  ST [FP, 0], C ; ap
  MOV SP, FP
  ADD SP, 8
  POP LR, FP
  ADD SP, 16
  RET
main:
  PUSH LR, B, FP
  SUB SP, 1
  MOV FP, SP
  LDI B, =stdin
  MOV A, B
  CALL fgetc
  MOV B, A
  ST.B [FP, 0], B ; c
  MOV B, 0
  JMP .L41
.L41:
  MOV A, B
  MOV SP, FP
  ADD SP, 1
  POP PC, B, FP