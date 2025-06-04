next_rand: .word 0
heapindex: .word 0
div:
  PUSH C, FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ADD A, FP, 8
  LD B, [FP, 0] ; num
  LD C, [FP, 4] ; den
  DIV B, C
  ST [A, 0], B
  LD B, [FP, 0] ; num
  LD C, [FP, 4] ; den
  MOD B, C
  ST [A, 4], B
  ADD A, FP, 8
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 16
  POP C, FP
  RET
abs:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; n
  CMP A, 0
  JGE .L2
  LD A, [FP, 0] ; n
  NEG A
  JMP .L1
.L2:
  LD A, [FP, 0] ; n
  JMP .L1
.L1:
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET
bsearch:
  PUSH LR, F, FP
  SUB SP, 32
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  MOV C, 0
  ST [FP, 16], C ; low
  LD C, [FP, 12] ; n
  SUB C, 1
  ST [FP, 24], C ; high
.L4:
  LD C, [FP, 16] ; low
  LD D, [FP, 24] ; high
  CMP C, D
  JGT .L5
  LD C, [FP, 16] ; low
  LD D, [FP, 24] ; high
  LD E, [FP, 16] ; low
  SUB D, E
  DIV D, 2
  ADD C, D
  ST [FP, 20], C ; mid
  LD C, [FP, 0] ; x
  LD D, [FP, 4] ; v
  LD E, [FP, 20] ; mid
  LD F, [FP, 8] ; size
  MUL E, F
  ADD D, E
  MOV A, C
  MOV B, D
  LD C, [FP, 44] ; cmp
  CALL C
  MOV C, A
  ST [FP, 28], C ; cond
  LD C, [FP, 28] ; cond
  CMP C, 0
  JGE .L7
  LD C, [FP, 20] ; mid
  SUB C, 1
  ST [FP, 24], C ; high
  JMP .L6
.L7:
  LD C, [FP, 28] ; cond
  CMP C, 0
  JLE .L8
  LD C, [FP, 20] ; mid
  ADD C, 1
  ST [FP, 16], C ; low
  JMP .L6
.L8:
  LD C, [FP, 20] ; mid
  LD D, [FP, 8] ; size
  MUL C, D
  JMP .L3
.L6:
  JMP .L4
.L5:
  MVN C, 1
  JMP .L3
.L3:
  MOV A, C
  MOV SP, FP
  ADD SP, 32
  POP PC, F, FP
swap:
  PUSH FP
  SUB SP, 33
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  LD A, [FP, 4] ; size
  DIV A, 4
  ST [FP, 16], A ; words
  LD A, [FP, 4] ; size
  MOD A, 4
  ST [FP, 20], A ; tail
  MOV A, 0
  ST [FP, 28], A ; k
.L9:
  LD A, [FP, 28] ; k
  LD B, [FP, 16] ; words
  CMP A, B
  JCS .L11
  LD A, [FP, 0] ; v
  LD B, [FP, 8] ; i
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 28] ; k
  ADD A, B
  LD A, [A]
  ST [FP, 24], A ; t
  LD A, [FP, 0] ; v
  LD B, [FP, 12] ; j
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 28] ; k
  ADD A, B
  LD A, [A]
  LD B, [FP, 0] ; v
  LD C, [FP, 8] ; i
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 28] ; k
  ADD B, C
  ST [B], A
  LD A, [FP, 24] ; t
  LD B, [FP, 0] ; v
  LD C, [FP, 12] ; j
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 28] ; k
  ADD B, C
  ST [B], A
.L10:
  LD A, [FP, 28] ; k
  ADD A, 4
  ST [FP, 28], A ; k
  JMP .L9
.L11:
  MOV A, 0
  ST.B [FP, 32], A ; c
.L12:
  LD.B A, [FP, 32] ; c
  LD B, [FP, 20] ; tail
  CMP A, B
  JCS .L14
  LD A, [FP, 0] ; v
  LD B, [FP, 8] ; i
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 28] ; k
  ADD A, B
  LD.B B, [FP, 32] ; c
  ADD A, B
  LD.B A, [A]
  ST [FP, 24], A ; t
  LD A, [FP, 0] ; v
  LD B, [FP, 12] ; j
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 28] ; k
  ADD A, B
  LD.B B, [FP, 32] ; c
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; v
  LD C, [FP, 8] ; i
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 28] ; k
  ADD B, C
  LD.B C, [FP, 32] ; c
  ADD B, C
  ST.B [B], A
  LD A, [FP, 24] ; t
  LD B, [FP, 0] ; v
  LD C, [FP, 12] ; j
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 28] ; k
  ADD B, C
  LD.B C, [FP, 32] ; c
  ADD B, C
  ST.B [B], A
.L13:
  LD.B A, [FP, 32] ; c
  ADD.B B, A, 1
  ST.B [FP, 32], B ; c
  JMP .L12
.L14:
  MOV SP, FP
  ADD SP, 33
  POP FP
  RET
qsort:
  PUSH LR, F, G, H, I, J, FP
  SUB SP, 24
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  LD E, [FP, 8] ; left
  LD F, [FP, 12] ; right
  CMP E, F
  JLT .L16
  JMP .L15
.L16:
  LD E, [FP, 0] ; v
  LD F, [FP, 4] ; size
  LD G, [FP, 8] ; left
  LD H, [FP, 8] ; left
  LD I, [FP, 12] ; right
  LD J, [FP, 8] ; left
  SUB I, J
  DIV I, 2
  ADD H, I
  MOV A, E
  MOV B, F
  MOV C, G
  MOV D, H
  CALL swap
  LD E, [FP, 8] ; left
  ST [FP, 20], E ; last
  LD E, [FP, 8] ; left
  ADD E, 1
  ST [FP, 16], E ; i
.L17:
  LD E, [FP, 16] ; i
  LD F, [FP, 12] ; right
  CMP E, F
  JGT .L19
  LD E, [FP, 0] ; v
  LD F, [FP, 16] ; i
  LD G, [FP, 4] ; size
  MUL F, G
  ADD E, F
  LD F, [FP, 0] ; v
  LD G, [FP, 8] ; left
  LD H, [FP, 4] ; size
  MUL G, H
  ADD F, G
  MOV A, E
  MOV B, F
  LD E, [FP, 52] ; cmp
  CALL E
  MOV E, A
  CMP E, 0
  JGE .L20
  LD E, [FP, 0] ; v
  LD F, [FP, 4] ; size
  LD G, [FP, 20] ; last
  ADD G, 1
  ST [FP, 20], G ; last
  LD H, [FP, 16] ; i
  MOV A, E
  MOV B, F
  MOV C, G
  MOV D, H
  CALL swap
.L20:
.L18:
  LD E, [FP, 16] ; i
  ADD F, E, 1
  ST [FP, 16], F ; i
  JMP .L17
.L19:
  LD E, [FP, 0] ; v
  LD F, [FP, 4] ; size
  LD G, [FP, 8] ; left
  LD H, [FP, 20] ; last
  MOV A, E
  MOV B, F
  MOV C, G
  MOV D, H
  CALL swap
  LD E, [FP, 0] ; v
  LD F, [FP, 4] ; size
  LD G, [FP, 8] ; left
  LD H, [FP, 20] ; last
  SUB H, 1
  LD I, [FP, 52] ; cmp
  MOV A, E
  MOV B, F
  MOV C, G
  MOV D, H
  PUSH I
  CALL qsort
  LD E, [FP, 0] ; v
  LD F, [FP, 4] ; size
  LD G, [FP, 20] ; last
  ADD G, 1
  LD H, [FP, 12] ; right
  LD I, [FP, 52] ; cmp
  MOV A, E
  MOV B, F
  MOV C, G
  MOV D, H
  PUSH I
  CALL qsort
.L15:
  MOV SP, FP
  ADD SP, 24
  POP PC, F, G, H, I, J, FP
rand:
  PUSH B, FP
  MOV FP, SP
  LDI A, 1103515245
  LDI B, =next_rand
  LD B, [B]
  MUL A, B
  LDI B, 12345
  ADD A, B
  LDI B, =next_rand
  ST [B], A
  LDI A, =next_rand
  LD A, [A]
  JMP .L21
.L21:
  MOV SP, FP
  POP B, FP
  RET
srand:
  PUSH B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; seed
  LDI B, =next_rand
  ST [B], A
  MOV SP, FP
  ADD SP, 4
  POP B, FP
  RET
atoi:
  PUSH B, C, FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 0
  ST [FP, 8], A ; n
  MOV A, 0
  ST [FP, 4], A ; i
.L23:
  MOV.B A, '0'
  LD B, [FP, 0] ; s
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JGT .L25
  LD A, [FP, 0] ; s
  LD B, [FP, 4] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '9'
  JGT .L25
  MOV A, 10
  LD B, [FP, 8] ; n
  MUL A, B
  LD B, [FP, 0] ; s
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B B, [B]
  SUB.B B, '0'
  ADD A, B
  ST [FP, 8], A ; n
.L24:
  LD A, [FP, 4] ; i
  ADD A, 1
  ST [FP, 4], A ; i
  JMP .L23
.L25:
  LD A, [FP, 8] ; n
  JMP .L22
.L22:
  MOV SP, FP
  ADD SP, 12
  POP B, C, FP
  RET
atof:
  PUSH B, C, FP
  SUB SP, 20
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 0
  ST [FP, 12], A ; i
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '-'
  JNE .L28
  MVN A, 1
  JMP .L27
.L28:
  MOV A, 1
.L27:
  ST [FP, 16], A ; sign
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '+'
  JEQ .L30
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '-'
  JNE .L29
.L30:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
.L29:
  LDI A, 0
  ST [FP, 4], A ; val
.L31:
  MOV.B A, '0'
  LD B, [FP, 0] ; s
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JGT .L33
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '9'
  JGT .L33
  LDI A, 1092616192
  LD B, [FP, 4] ; val
  MULF A, B
  LD B, [FP, 0] ; s
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  SUB.B B, '0'
  ITF B, B
  ADDF A, B
  ST [FP, 4], A ; val
.L32:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L31
.L33:
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '.'
  JNE .L34
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
.L34:
  LDI A, 1065353216
  ST [FP, 8], A ; pow
.L35:
  MOV.B A, '0'
  LD B, [FP, 0] ; s
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JGT .L37
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '9'
  JGT .L37
  LDI A, 1092616192
  LD B, [FP, 4] ; val
  MULF A, B
  LD B, [FP, 0] ; s
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  SUB.B B, '0'
  ITF B, B
  ADDF A, B
  ST [FP, 4], A ; val
  LD A, [FP, 8] ; pow
  LDI B, 1092616192
  MULF A, B
  ST [FP, 8], A ; pow
.L36:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L35
.L37:
  LD A, [FP, 16] ; sign
  ITF A, A
  LD B, [FP, 4] ; val
  MULF A, B
  LD B, [FP, 8] ; pow
  DIVF A, B
  JMP .L26
.L26:
  MOV SP, FP
  ADD SP, 20
  POP B, C, FP
  RET
malloc:
  PUSH B, C, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LDI A, =stdheap
  LDI B, =heapindex
  LD B, [B]
  LD C, [FP, 0] ; bytes
  ADD B, C
  LDI C, =heapindex
  ST [C], B
  ADD A, B
  ST [FP, 4], A ; ptr
  LD A, [FP, 4] ; ptr
  JMP .L38
.L38:
  MOV SP, FP
  ADD SP, 8
  POP B, C, FP
  RET
free:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET
realloc:
  PUSH LR, C, D, E, F, FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD D, [FP, 4] ; size
  MOV A, D
  CALL malloc
  MOV D, A
  ST [FP, 8], D ; d
  LD D, [FP, 8] ; d
  LD E, [FP, 0] ; p
  LD F, [FP, 4] ; size
  MOV A, D
  MOV B, E
  MOV C, F
  CALL memcpy
  LD D, [FP, 0] ; p
  MOV A, D
  CALL free
  LD D, [FP, 8] ; d
  JMP .L39
.L39:
  MOV A, D
  MOV SP, FP
  ADD SP, 12
  POP PC, C, D, E, F, FP
calloc:
  PUSH LR, C, D, FP
  SUB SP, 32
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD B, [FP, 0] ; n
  LD C, [FP, 4] ; size
  MUL B, C
  ST [FP, 8], B ; bytes
  LD B, [FP, 8] ; bytes
  DIV B, 4
  ST [FP, 12], B ; words
  LD B, [FP, 8] ; bytes
  MOD B, 4
  ST [FP, 16], B ; tail
  LD B, [FP, 8] ; bytes
  MOV A, B
  CALL malloc
  MOV B, A
  ST [FP, 24], B ; p
  MOV B, 0
  ST [FP, 20], B ; i
.L41:
  LD B, [FP, 20] ; i
  LD C, [FP, 12] ; words
  CMP B, C
  JCS .L43
  MOV B, 0
  LD C, [FP, 24] ; p
  LD D, [FP, 20] ; i
  ADD C, D
  ST [C], B
.L42:
  LD B, [FP, 20] ; i
  ADD C, B, 1
  ST [FP, 20], C ; i
  JMP .L41
.L43:
  MOV B, 0
  ST [FP, 28], B ; c
.L44:
  LD B, [FP, 28] ; c
  LD C, [FP, 16] ; tail
  CMP B, C
  JCS .L46
  MOV B, 0
  LD C, [FP, 24] ; p
  LD D, [FP, 20] ; i
  ADD C, D
  LD D, [FP, 28] ; c
  ADD C, D
  ST.B [C], B
.L45:
  LD B, [FP, 28] ; c
  ADD C, B, 1
  ST [FP, 28], C ; c
  JMP .L44
.L46:
  LD B, [FP, 24] ; p
  JMP .L40
.L40:
  MOV A, B
  MOV SP, FP
  ADD SP, 32
  POP PC, C, D, FP