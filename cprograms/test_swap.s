stdout: .word 2147483648
stdin: .word 2147483649
.S0: "%d %d\n\0"
.S1: "%d\n\0"
fgetc:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; next
  LD A, [A]
  LD.B A, [A]
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET
getchar:
  PUSH FP
  MOV FP, SP
  LDI A, =stdin
  LD A, [A]
  LD.B A, [A]
  JMP .L1
.L1:
  MOV SP, FP
  POP FP
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
.L3:
  LD B, [FP, 4] ; n
  SUB B, 1
  ST [FP, 4], B ; n
  CMP B, 0
  JLS .L4
  LD B, [FP, 8] ; stream
  MOV A, B
  CALL fgetc
  MOV B, A
  ST.B [FP, 12], B ; c
  CMP.B B, 0
  JEQ .L4
  LD.B B, [FP, 12] ; c
  LD C, [FP, 13] ; cs
  ADD D, C, 1
  ST [FP, 13], D ; cs
  ST.B [C], B
  CMP.B B, '\n'
  JNE .L5
  JMP .L4
.L5:
  JMP .L3
.L4:
  MOV.B B, '\0'
  LD C, [FP, 13] ; cs
  ST.B [C], B
  LD B, [FP, 0] ; s
  JMP .L2
.L2:
  MOV A, B
  MOV SP, FP
  ADD SP, 17
  POP PC, D, FP
gets:
  PUSH LR, C, D, E, FP
  SUB SP, 13
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  MOV B, 0
  ST [FP, 9], B ; i
.L7:
  CALL getchar
  MOV B, A
  ST.B [FP, 8], B ; c
  CMP.B B, '\n'
  JEQ .L8
  LD.B B, [FP, 8] ; c
  CMP.B B, 0
  JEQ .L9
  LD.B B, [FP, 8] ; c
  CMP.B B, '\b'
  JNE .L11
  LD.B B, [FP, 8] ; c
  MOV.B A, B
  CALL putchar
  LD B, [FP, 9] ; i
  CMP B, 0
  JLS .L12
  LD B, [FP, 9] ; i
  SUB C, B, 1
  ST [FP, 9], C ; i
.L12:
  JMP .L10
.L11:
  LD B, [FP, 9] ; i
  LD C, [FP, 4] ; n
  SUB C, 1
  CMP B, C
  JCS .L10
  LD.B B, [FP, 8] ; c
  MOV.B A, B
  CALL putchar
  LD.B B, [FP, 8] ; c
  LD C, [FP, 0] ; s
  LD D, [FP, 9] ; i
  ADD E, D, 1
  ST [FP, 9], E ; i
  ADD C, D
  ST.B [C], B
.L10:
.L9:
  JMP .L7
.L8:
  MOV.B B, '\0'
  LD C, [FP, 0] ; s
  LD D, [FP, 9] ; i
  ADD C, D
  ST.B [C], B
  LD B, [FP, 0] ; s
  JMP .L6
.L6:
  MOV A, B
  MOV SP, FP
  ADD SP, 13
  POP PC, C, D, E, FP
fputc:
  PUSH FP
  SUB SP, 5
  MOV FP, SP
  ST.B [FP, 0], A
  ST [FP, 1], B
  LD.B A, [FP, 0] ; c
  LD B, [FP, 1] ; next
  LD B, [B]
  ST.B [B], A
  MOV A, 0
  JMP .L13
.L13:
  MOV SP, FP
  ADD SP, 5
  POP FP
  RET
putchar:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B A, [FP, 0] ; c
  LDI B, =stdout
  LD B, [B]
  ST.B [B], A
  MOV A, 0
  JMP .L14
.L14:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
fputs:
  PUSH LR, C, D, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
.L16:
  LD C, [FP, 0] ; s
  LD.B C, [C]
  CMP.B C, '\0'
  JEQ .L17
  LD C, [FP, 0] ; s
  LD.B C, [C]
  LD D, [FP, 4] ; stream
  MOV.B A, C
  MOV B, D
  CALL fputc
  LD C, [FP, 0] ; s
  ADD D, C, 1
  ST [FP, 0], D ; s
  JMP .L16
.L17:
  MOV C, 0
  JMP .L15
.L15:
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
  JMP .L18
.L18:
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
  JEQ .L19
  LD B, [FP, 0] ; n
  DIV B, 10
  MOV A, B
  CALL uprint
.L19:
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
  JGE .L20
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; n
  NEG B
  ST [FP, 0], B ; n
.L20:
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
  JEQ .L21
  LD C, [FP, 0] ; n
  DIV C, 16
  LD.B D, [FP, 4] ; uplo
  MOV A, C
  MOV.B B, D
  CALL xprint
.L21:
  LD C, [FP, 0] ; n
  MOD C, 16
  CMP C, 9
  JLS .L23
  LD C, [FP, 0] ; n
  MOD C, 16
  SUB C, 10
  LD.B D, [FP, 4] ; uplo
  ADD C, D
  MOV A, C
  CALL putchar
  JMP .L22
.L23:
  LD C, [FP, 0] ; n
  MOD C, 16
  ADD C, '0'
  MOV A, C
  CALL putchar
.L22:
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
  JGE .L24
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; f
  NEGF B
  ST [FP, 0], B ; f
.L24:
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
.L25:
  LD.B B, [FP, 4] ; prec
  CMP B, 0
  JLE .L27
  LD B, [FP, 9] ; p
  MUL B, 10
  ST [FP, 9], B ; p
.L26:
  LD.B B, [FP, 4] ; prec
  SUB.B B, 1
  ST.B [FP, 4], B ; prec
  JMP .L25
.L27:
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
.L28:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, 0
  JEQ .L30
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, '%'
  JNE .L32
  LD C, [FP, 4] ; c
  ADD C, 1
  ST [FP, 4], C ; c
  LD.B C, [C]
  CMP.B C, 'u'
  JEQ .L35
  CMP.B C, 'i'
  JEQ .L36
  CMP.B C, 'd'
  JEQ .L37
  CMP.B C, 'x'
  JEQ .L38
  CMP.B C, 'X'
  JEQ .L39
  CMP.B C, 's'
  JEQ .L40
  CMP.B C, 'c'
  JEQ .L41
  JMP .L42
.L35:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL uprint
  JMP .L34
.L36:
.L37:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL dprint
  JMP .L34
.L38:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV.B D, 'a'
  MOV A, C
  MOV.B B, D
  CALL xprint
  JMP .L34
.L39:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV.B D, 'A'
  MOV A, C
  MOV.B B, D
  CALL xprint
  JMP .L34
.L40:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL printf
  JMP .L34
.L41:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV.B A, C
  CALL putchar
  JMP .L34
.L42:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
.L34:
  JMP .L31
.L32:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
.L31:
.L29:
  LD C, [FP, 4] ; c
  ADD D, C, 1
  ST [FP, 4], D ; c
  JMP .L28
.L30:
  MOV C, 0
  ST [FP, 0], C ; ap
  MOV SP, FP
  ADD SP, 8
  POP LR, FP
  ADD SP, 16
  RET
foo:
  PUSH LR, A, B, C, D, E, F, G, H, FP
  SUB SP, 8
  MOV FP, SP
  ADD E, FP, 0
  LDI F, 1234
  ST [E, 0], F
  LDI F, 5678
  ST [E, 4], F
  LDI E, =.S0
  ADD F, FP, 0
  MOV G, 0
  MUL G, 4
  ADD F, G
  LD F, [F]
  ADD G, FP, 0
  MOV H, 1
  MUL H, 4
  ADD G, H
  LD G, [G]
  MOV A, E
  MOV B, F
  MOV C, G
  CALL printf
  ADD E, FP, 0
  MOV F, 4
  MOV G, 0
  MOV H, 1
  MOV A, E
  MOV B, F
  MOV C, G
  MOV D, H
  CALL swap
  LDI E, =.S0
  ADD F, FP, 0
  MOV G, 0
  MUL G, 4
  ADD F, G
  LD F, [F]
  ADD G, FP, 0
  MOV H, 1
  MUL H, 4
  ADD G, H
  LD G, [G]
  MOV A, E
  MOV B, F
  MOV C, G
  CALL printf
  MOV SP, FP
  ADD SP, 8
  POP PC, A, B, C, D, E, F, G, H, FP
swap:
  PUSH LR, E, FP
  SUB SP, 20
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  LD C, [FP, 0] ; v
  LD D, [FP, 8] ; i
  ADD C, D
  LD C, [C]
  ST [FP, 16], C ; t
  LD C, [FP, 0] ; v
  LD D, [FP, 8] ; i
  ADD C, D
  LD C, [C]
  ST [FP, 16], C ; t
  LDI C, =.S1
  LD D, [FP, 16] ; t
  MOV A, C
  MOV B, D
  CALL printf
  LD C, [FP, 0] ; v
  LD D, [FP, 12] ; j
  ADD C, D
  LD C, [C]
  LD D, [FP, 0] ; v
  LD E, [FP, 8] ; i
  ADD D, E
  ST [D], C
  LDI C, =.S1
  LD D, [FP, 0] ; v
  LD E, [FP, 8] ; i
  ADD D, E
  LD D, [D]
  MOV A, C
  MOV B, D
  CALL printf
  LD C, [FP, 16] ; t
  LD D, [FP, 0] ; v
  LD E, [FP, 12] ; j
  ADD D, E
  ST [D], C
  MOV SP, FP
  ADD SP, 20
  POP PC, E, FP
main:
  PUSH LR, FP
  MOV FP, SP
  CALL foo
.L43:
  MOV SP, FP
  POP PC, FP