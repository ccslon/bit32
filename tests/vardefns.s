.S0: "%d%d%d%d%d\0"
printf:
  PUSH A, B, C, D
  PUSH B, C, LR
  SUB SP, 17
  ADD A, SP, 29
  MOV B, 1
  MUL B, 4
  ADD A, B
  ST [SP, 4], A ; ap
  MOV A, 0
  ST [SP, 12], A ; n
  LD A, [SP, 29] ; format
  ST [SP, 8], A ; c
.L0:
  LD A, [SP, 8] ; c
  LD.B A, [A]
  CMP.B A, 0
  JEQ .L2
  LD A, [SP, 8] ; c
  LD.B A, [A]
  CMP.B A, '%'
  JNE .L4
  LD A, [SP, 8] ; c
  ADD B, A, 1
  ST [SP, 8], B ; c
  MOV A, 0
  ST.B [SP, 16], A ; precision
  MOV.B A, '0'
  LD B, [SP, 8] ; c
  LD.B B, [B]
  CMP.B A, B
  JGT .L5
  LD A, [SP, 8] ; c
  LD.B A, [A]
  CMP.B A, '9'
  JGT .L5
  LD A, [SP, 8] ; c
  ADD B, A, 1
  ST [SP, 8], B ; c
  LD.B A, [A]
  SUB.B A, '0'
  ST.B [SP, 16], A ; precision
.L5:
  LD A, [SP, 8] ; c
  LD.B A, [A]
  CMP.B A, 'u'
  JEQ .L8
  CMP.B A, 'd'
  JEQ .L9
  CMP.B A, 'i'
  JEQ .L10
  CMP.B A, 'x'
  JEQ .L11
  CMP.B A, 'X'
  JEQ .L12
  CMP.B A, 'f'
  JEQ .L13
  CMP.B A, 'e'
  JEQ .L14
  CMP.B A, 's'
  JEQ .L15
  CMP.B A, 'c'
  JEQ .L16
  CMP.B A, 'o'
  JEQ .L17
  CMP.B A, 'n'
  JEQ .L18
  JMP .L19
.L8:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD A, [A]
  CALL uprint
  JMP .L7
.L9:
.L10:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD A, [A]
  CALL dprint
  JMP .L7
.L11:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD A, [A]
  MOV.B B, 'a'
  CALL xprint
  JMP .L7
.L12:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD A, [A]
  MOV.B B, 'A'
  CALL xprint
  JMP .L7
.L13:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD A, [A]
  LD.B B, [SP, 16] ; precision
  CALL fprint
  JMP .L7
.L14:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD A, [A]
  LD.B B, [SP, 16] ; precision
  CALL eprint
  JMP .L7
.L15:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD A, [A]
  CALL printf
  JMP .L7
.L16:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD.B A, [A]
  CALL putchar
  JMP .L7
.L17:
  LD A, [SP, 4] ; ap
  ADD B, A, 4
  ST [SP, 4], B ; ap
  LD A, [A]
  CALL oprint
  JMP .L7
.L18:
  LD A, [SP, 12] ; n
  LD B, [SP, 4] ; ap
  ADD C, B, 4
  ST [SP, 4], C ; ap
  LD B, [B]
  ST [B], A
  JMP .L7
.L19:
  LD A, [SP, 8] ; c
  LD.B A, [A]
  CALL putchar
.L7:
  JMP .L3
.L4:
  LD A, [SP, 8] ; c
  LD.B A, [A]
  CALL putchar
.L3:
.L1:
  LD A, [SP, 8] ; c
  ADD B, A, 1
  ST [SP, 8], B ; c
  LD A, [SP, 12] ; n
  ADD B, A, 1
  ST [SP, 12], B ; n
  JMP .L0
.L2:
  MOV A, 0
  ST [SP, 4], A ; ap
  ADD SP, 17
  POP B, C, LR
  ADD SP, 16
  RET
main:
  PUSH B, C, D, E, F, LR
  LDI A, =.S0
  MOV B, 1
  MOV C, 2
  MOV D, 3
  MOV E, 4
  MOV F, 5
  PUSH F
  PUSH E
  CALL printf
  ADD SP, 8
.L20:
  POP B, C, D, E, F, PC