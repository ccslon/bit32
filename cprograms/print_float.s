stdout: WORD 2147483648
stdin: WORD 2147483649
fgetc:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  LD [FP, 0], A
  LD A, [FP, 0] ; stream
  LD A, [A]
  LD A, [A]
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET
getchar:
  PUSH FP
  MOV FP, SP
  LD A, =stdin
  LD A, [A]
  LD A, [A]
  JMP .L1
.L1:
  MOV SP, FP
  POP FP
  RET
fgets:
  PUSH LR, D, FP
  SUB SP, 17
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
  LD [FP, 8], C
  LD B, [FP, 0] ; s
  LD [FP, 13], B ; cs
.L3:
  LD B, [FP, 4] ; n
  SUB B, 1
  LD [FP, 4], B ; n
  CMP B, 0
  MOVGT B, 1
  MOVLE B, 0
  CMP B, 0
  JEQ .L4
  LD B, [FP, 8] ; stream
  MOV A, B
  CALL fgetc
  MOV.B B, A
  LD.B [FP, 12], B ; c
  CMP B, 0
  JEQ .L4
  LD.B B, [FP, 12] ; c
  LD C, [FP, 13] ; cs
  ADD D, C, 1
  LD [FP, 13], D ; cs
  LD.B [C], B
  CMP.B B, '\n'
  JNE .L5
  JMP .L4
.L5:
  JMP .L3
.L4:
  MOV.B B, '\0'
  LD C, [FP, 13] ; cs
  LD.B [C], B
  LD B, [FP, 0] ; s
  JMP .L2
.L2:
  MOV A, B
  MOV SP, FP
  ADD SP, 17
  POP PC, D, FP
gets:
  PUSH LR, B, C, D, E, F, FP
  SUB SP, 4
  MOV FP, SP
  LD [FP, 0], A
  LD D, [FP, 0] ; s
  MOV E, 255
  LD F, =stdin
  MOV A, D
  MOV B, E
  MOV C, F
  CALL fgets
  MOV D, A
  JMP .L6
.L6:
  MOV A, D
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, D, E, F, FP
fputc:
  PUSH FP
  SUB SP, 5
  MOV FP, SP
  LD.B [FP, 0], A
  LD [FP, 1], B
  LD.B A, [FP, 0] ; c
  LD B, [FP, 1] ; stream
  LD B, [B]
  LD [B], A
  MOV A, 0
  JMP .L7
.L7:
  MOV SP, FP
  ADD SP, 5
  POP FP
  RET
putchar:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  LD.B [FP, 0], A
  LD.B A, [FP, 0] ; c
  LD B, =stdout
  LD B, [B]
  LD [B], A
  MOV A, 0
  JMP .L8
.L8:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
fputs:
  PUSH LR, C, D, FP
  SUB SP, 8
  MOV FP, SP
  LD [FP, 0], A
  LD [FP, 4], B
.L10:
  LD C, [FP, 0] ; s
  LD.B C, [C]
  CMP.B C, '\0'
  JEQ .L11
  LD C, [FP, 0] ; s
  LD.B C, [C]
  LD D, [FP, 4] ; stream
  MOV.B A, C
  MOV B, D
  CALL fputc
  MOV C, A
  LD C, [FP, 0] ; s
  ADD D, C, 1
  LD [FP, 0], D ; s
  JMP .L10
.L11:
  MOV C, 0
  JMP .L9
.L9:
  MOV A, C
  MOV SP, FP
  ADD SP, 8
  POP PC, C, D, FP
puts:
  PUSH LR, B, C, D, FP
  SUB SP, 4
  MOV FP, SP
  LD [FP, 0], A
  LD C, [FP, 0] ; s
  LD D, =stdout
  MOV A, C
  MOV B, D
  CALL fputs
  MOV C, A
  MOV.B C, '\n'
  MOV.B A, C
  CALL putchar
  MOV C, A
  MOV C, 0
  JMP .L12
.L12:
  MOV A, C
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, D, FP
dprint:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  LD [FP, 0], A
  LD B, [FP, 0] ; n
  CMP B, 0
  JGE .L13
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  MOV B, A
  LD B, [FP, 0] ; n
  NEG B
  LD [FP, 0], B ; n
.L13:
  LD B, [FP, 0] ; n
  DIV B, 10
  CMP B, 0
  JEQ .L14
  LD B, [FP, 0] ; n
  DIV B, 10
  MOV A, B
  CALL dprint
.L14:
  LD B, [FP, 0] ; n
  MOD B, 10
  ADD B, '0'
  MOV A, B
  CALL putchar
  MOV B, A
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
xprint:
  PUSH LR, C, D, FP
  SUB SP, 5
  MOV FP, SP
  LD [FP, 0], A
  LD.B [FP, 4], B
  LD C, [FP, 0] ; n
  CMP C, 0
  JGE .L15
  MOV.B C, '-'
  MOV.B A, C
  CALL putchar
  MOV C, A
  LD C, [FP, 0] ; n
  NEG C
  LD [FP, 0], C ; n
.L15:
  LD C, [FP, 0] ; n
  DIV C, 16
  CMP C, 0
  JEQ .L16
  LD C, [FP, 0] ; n
  DIV C, 16
  LD.B D, [FP, 4] ; uplo
  MOV A, C
  MOV.B B, D
  CALL xprint
.L16:
  LD C, [FP, 0] ; n
  MOD C, 16
  CMP C, 9
  JLE .L18
  LD C, [FP, 0] ; n
  MOD C, 16
  SUB C, 10
  LD.B D, [FP, 4] ; uplo
  ADD C, D
  MOV A, C
  CALL putchar
  MOV C, A
  JMP .L17
.L18:
  LD C, [FP, 0] ; n
  MOD C, 16
  ADD C, '0'
  MOV A, C
  CALL putchar
  MOV C, A
.L17:
  MOV SP, FP
  ADD SP, 5
  POP PC, C, D, FP
fprint:
  PUSH LR, B, C, FP
  SUB SP, 9
  MOV FP, SP
  LD [FP, 0], A
  LD B, [FP, 0] ; f
  MOV C, 0
  ITF C, C
  CMPF B, C
  JGE .L19
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  MOV B, A
  LD B, [FP, 0] ; f
  NEGF B
  LD [FP, 0], B ; f
.L19:
  LD B, [FP, 0] ; f
  MOV C, 255
  SHL C, 23
  AND B, C
  SHR B, 23
  SUB B, 127
  LD.B [FP, 4], B ; exp
  LD B, [FP, 0] ; f
  LD C, 8388607
  AND B, C
  LD C, 134217728
  OR B, C
  LD [FP, 5], B ; mant
  LD B, [FP, 5] ; mant
  MOV A, B
  CALL dprint
  MOV.B B, 'e'
  MOV.B A, B
  CALL putchar
  MOV B, A
  LD.B B, [FP, 4] ; exp
  MOV.B A, B
  CALL dprint
  MOV SP, FP
  ADD SP, 9
  POP PC, B, C, FP
printf:
  PUSH D, C, B, A
  PUSH LR, FP
  SUB SP, 8
  MOV FP, SP
  ADD C, FP, 16
  ADD C, 4
  LD [FP, 0], C ; ap
  LD C, [FP, 16] ; format
  LD [FP, 4], C ; c
.L20:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, 0
  JEQ .L22
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, '%'
  JNE .L24
  LD C, [FP, 4] ; c
  ADD C, 1
  LD [FP, 4], C ; c
  LD.B C, [C]
  CMP.B C, 'i'
  JEQ .L27
  CMP.B C, 'd'
  JEQ .L28
  CMP.B C, 'x'
  JEQ .L29
  CMP.B C, 'X'
  JEQ .L30
  CMP.B C, 's'
  JEQ .L31
  CMP.B C, 'c'
  JEQ .L32
  JMP .L33
.L27:
.L28:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  LD [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL dprint
  JMP .L26
.L29:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  LD [FP, 0], D ; ap
  LD C, [C]
  MOV.B D, 'a'
  MOV A, C
  MOV.B B, D
  CALL xprint
  JMP .L26
.L30:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  LD [FP, 0], D ; ap
  LD C, [C]
  MOV.B D, 'A'
  MOV A, C
  MOV.B B, D
  CALL xprint
  JMP .L26
.L31:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  LD [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL printf
  JMP .L26
.L32:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  LD [FP, 0], D ; ap
  LD C, [C]
  MOV.B A, C
  CALL putchar
  MOV C, A
  JMP .L26
.L33:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
  MOV C, A
.L26:
  JMP .L23
.L24:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
  MOV C, A
.L23:
.L21:
  LD C, [FP, 4] ; c
  ADD D, C, 1
  LD [FP, 4], D ; c
  JMP .L20
.L22:
  MOV C, 0
  LD [FP, 0], C ; ap
  MOV SP, FP
  ADD SP, 8
  POP LR, FP
  ADD SP, 16
  RET
main:
  PUSH LR, B, FP
  MOV FP, SP
  LD B, 134217728
  MOV A, B
  CALL dprint
.L34:
  MOV A, B
  MOV SP, FP
  POP PC, B, FP