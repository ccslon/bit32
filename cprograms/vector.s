next_rand: .word 0
heapindex: .word 0
.S0: "%s\n\0"
.S1: "Hello my name is Colin Hello my name is Colin\0"
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
  PUSH B, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LDI A, =stdheap
  LDI B, =heapindex
  LD B, [B]
  MUL B, 4
  ADD A, B
  ST [FP, 4], A ; ptr
  LDI A, =heapindex
  LD A, [A]
  LD B, [FP, 0] ; bytes
  ADD A, B
  LDI B, =heapindex
  ST [B], A
  LD A, [FP, 4] ; ptr
  JMP .L38
.L38:
  MOV SP, FP
  ADD SP, 8
  POP B, FP
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
strlen:
  PUSH B, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 0
  ST [FP, 4], A ; l
.L48:
  LD A, [FP, 0] ; s
  LD B, [FP, 4] ; l
  ADD A, B
  LD.B A, [A]
  CMP.B A, '\0'
  JEQ .L49
  LD A, [FP, 4] ; l
  ADD B, A, 1
  ST [FP, 4], B ; l
  JMP .L48
.L49:
  LD A, [FP, 4] ; l
  JMP .L47
.L47:
  MOV SP, FP
  ADD SP, 8
  POP B, FP
  RET
strcpy:
  PUSH C, FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  MOV A, 0
  ST [FP, 8], A ; i
.L51:
  LD A, [FP, 4] ; t
  LD B, [FP, 8] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 8] ; i
  ADD B, C
  ST.B [B], A
  CMP.B A, '\0'
  JEQ .L53
.L52:
  LD A, [FP, 8] ; i
  ADD B, A, 1
  ST [FP, 8], B ; i
  JMP .L51
.L53:
  LD A, [FP, 0] ; s
  JMP .L50
.L50:
  MOV SP, FP
  ADD SP, 12
  POP C, FP
  RET
strncpy:
  PUSH FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  MOV A, 0
  ST [FP, 12], A ; i
.L55:
  LD A, [FP, 12] ; i
  LD B, [FP, 8] ; n
  CMP A, B
  JCS .L57
  LD A, [FP, 4] ; t
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 12] ; i
  ADD B, C
  ST.B [B], A
  CMP.B A, '\0'
  JEQ .L57
.L56:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L55
.L57:
  LD A, [FP, 0] ; s
  JMP .L54
.L54:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
strdup:
  PUSH LR, B, C, D, E, F, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LD D, [FP, 0] ; s
  MOV A, D
  CALL strlen
  MOV D, A
  ADD D, 1
  MOV A, D
  CALL malloc
  MOV D, A
  ST [FP, 4], D ; p
  LD D, [FP, 4] ; p
  MOV E, 0
  CMP D, E
  JEQ .L59
  LD D, [FP, 4] ; p
  LD E, [FP, 0] ; s
  LD F, [FP, 0] ; s
  MOV A, F
  CALL strlen
  MOV F, A
  ADD F, 1
  MOV A, D
  MOV B, E
  MOV C, F
  CALL strncpy
.L59:
  LD D, [FP, 4] ; p
  JMP .L58
.L58:
  MOV A, D
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, D, E, F, FP
strcat:
  PUSH LR, C, D, E, FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD B, [FP, 0] ; s
  MOV A, B
  CALL strlen
  MOV B, A
  ST [FP, 8], B ; i
  MOV B, 0
  ST [FP, 12], B ; j
.L61:
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; j
  ADD D, C, 1
  ST [FP, 12], D ; j
  ADD B, C
  LD.B B, [B]
  LD C, [FP, 0] ; s
  LD D, [FP, 8] ; i
  ADD E, D, 1
  ST [FP, 8], E ; i
  ADD C, D
  ST.B [C], B
  CMP.B B, '\0'
  JEQ .L62
  JMP .L61
.L62:
  LD B, [FP, 0] ; s
  JMP .L60
.L60:
  MOV A, B
  MOV SP, FP
  ADD SP, 16
  POP PC, C, D, E, FP
strrev:
  PUSH LR, B, C, D, FP
  SUB SP, 13
  MOV FP, SP
  ST [FP, 0], A
  MOV B, 0
  ST [FP, 4], B ; front
  LD B, [FP, 0] ; s
  MOV A, B
  CALL strlen
  MOV B, A
  SUB B, 1
  ST [FP, 8], B ; back
.L64:
  LD B, [FP, 4] ; front
  LD C, [FP, 8] ; back
  CMP B, C
  JCS .L66
  LD B, [FP, 0] ; s
  LD C, [FP, 4] ; front
  ADD B, C
  LD.B B, [B]
  ST.B [FP, 12], B ; temp
  LD B, [FP, 0] ; s
  LD C, [FP, 8] ; back
  ADD B, C
  LD.B B, [B]
  LD C, [FP, 0] ; s
  LD D, [FP, 4] ; front
  ADD C, D
  ST.B [C], B
  LD.B B, [FP, 12] ; temp
  LD C, [FP, 0] ; s
  LD D, [FP, 8] ; back
  ADD C, D
  ST.B [C], B
.L65:
  LD B, [FP, 4] ; front
  ADD C, B, 1
  ST [FP, 4], C ; front
  LD B, [FP, 8] ; back
  SUB C, B, 1
  ST [FP, 8], C ; back
  JMP .L64
.L66:
  LD B, [FP, 0] ; s
  JMP .L63
.L63:
  MOV A, B
  MOV SP, FP
  ADD SP, 13
  POP PC, B, C, D, FP
strcmp:
  PUSH C, FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  MOV A, 0
  ST [FP, 8], A ; i
.L68:
  LD A, [FP, 0] ; s
  LD B, [FP, 8] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 8] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JNE .L70
  LD A, [FP, 0] ; s
  LD B, [FP, 8] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '\0'
  JNE .L71
  MOV A, 0
  JMP .L67
.L71:
.L69:
  LD A, [FP, 8] ; i
  ADD B, A, 1
  ST [FP, 8], B ; i
  JMP .L68
.L70:
  LD A, [FP, 0] ; s
  LD B, [FP, 8] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 8] ; i
  ADD B, C
  LD.B B, [B]
  SUB A, B
  JMP .L67
.L67:
  MOV SP, FP
  ADD SP, 12
  POP C, FP
  RET
strncmp:
  PUSH FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  MOV A, 0
  ST [FP, 12], A ; i
.L73:
  LD A, [FP, 12] ; i
  LD B, [FP, 8] ; n
  CMP A, B
  JCS .L75
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JNE .L75
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '\0'
  JNE .L76
  MOV A, 0
  JMP .L72
.L76:
.L74:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L73
.L75:
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  SUB A, B
  JMP .L72
.L72:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
strchr:
  PUSH FP
  SUB SP, 9
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  MOV A, 0
  ST [FP, 5], A ; i
.L78:
  LD A, [FP, 0] ; s
  LD B, [FP, 5] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '\0'
  JEQ .L80
  LD A, [FP, 0] ; s
  LD B, [FP, 5] ; i
  ADD A, B
  LD.B A, [A]
  LD.B B, [FP, 4] ; c
  CMP.B A, B
  JNE .L81
  LD A, [FP, 0] ; s
  LD B, [FP, 5] ; i
  ADD A, B
  JMP .L77
.L81:
.L79:
  LD A, [FP, 5] ; i
  ADD B, A, 1
  ST [FP, 5], B ; i
  JMP .L78
.L80:
  MOV A, 0
  JMP .L77
.L77:
  MOV SP, FP
  ADD SP, 9
  POP FP
  RET
memset:
  PUSH FP
  SUB SP, 13
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  ST [FP, 5], C
  MOV A, 0
  ST [FP, 9], A ; i
.L83:
  LD A, [FP, 9] ; i
  LD B, [FP, 5] ; n
  CMP A, B
  JCS .L85
  LD.B A, [FP, 4] ; v
  LD B, [FP, 0] ; s
  LD C, [FP, 9] ; i
  ADD B, C
  ST.B [B], A
.L84:
  LD A, [FP, 9] ; i
  ADD B, A, 1
  ST [FP, 9], B ; i
  JMP .L83
.L85:
  LD A, [FP, 0] ; s
  JMP .L82
.L82:
  MOV SP, FP
  ADD SP, 13
  POP FP
  RET
memcpy:
  PUSH FP
  SUB SP, 28
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 8] ; n
  DIV A, 4
  ST [FP, 12], A ; words
  LD A, [FP, 8] ; n
  MOD A, 4
  ST [FP, 16], A ; tail
  MOV A, 0
  ST [FP, 20], A ; i
.L87:
  LD A, [FP, 20] ; i
  LD B, [FP, 12] ; words
  CMP A, B
  JCS .L89
  LD A, [FP, 4] ; t
  LD B, [FP, 20] ; i
  ADD A, B
  LD A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 20] ; i
  ADD B, C
  ST [B], A
.L88:
  LD A, [FP, 20] ; i
  ADD B, A, 1
  ST [FP, 20], B ; i
  JMP .L87
.L89:
  MOV A, 0
  ST [FP, 24], A ; c
.L90:
  LD A, [FP, 24] ; c
  LD B, [FP, 16] ; tail
  CMP A, B
  JCS .L92
  LD A, [FP, 4] ; t
  LD B, [FP, 20] ; i
  ADD A, B
  LD B, [FP, 24] ; c
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 20] ; i
  ADD B, C
  LD C, [FP, 24] ; c
  ADD B, C
  ST.B [B], A
.L91:
  LD A, [FP, 24] ; c
  ADD B, A, 1
  ST [FP, 24], B ; c
  JMP .L90
.L92:
  LD A, [FP, 0] ; s
  JMP .L86
.L86:
  MOV SP, FP
  ADD SP, 28
  POP FP
  RET
memcmp:
  PUSH FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  MOV A, 0
  ST [FP, 12], A ; i
.L94:
  LD A, [FP, 12] ; i
  LD B, [FP, 8] ; n
  CMP A, B
  JCS .L96
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JEQ .L97
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  SUB A, B
  JMP .L93
.L97:
.L95:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L94
.L96:
  MOV A, 0
  JMP .L93
.L93:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
fgetc:
  PUSH B, FP
  SUB SP, 5
  MOV FP, SP
  ST [FP, 0], A
.L99:
  LD A, [FP, 0] ; stream
  LD A, [A, 4] ; read
  LD B, [FP, 0] ; stream
  LD B, [B, 8] ; write
  CMP A, B
  JNE .L100
  JMP .L99
.L100:
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
  JMP .L98
.L98:
  MOV SP, FP
  ADD SP, 5
  POP B, FP
  RET
getchar:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
.L102:
  LDI A, =stdin
  LD A, [A, 4] ; read
  LDI B, =stdin
  LD B, [B, 8] ; write
  CMP A, B
  JNE .L103
  JMP .L102
.L103:
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
  JMP .L101
.L101:
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
.L105:
  LD B, [FP, 4] ; n
  SUB B, 1
  ST [FP, 4], B ; n
  CMP B, 0
  JLS .L106
  LD B, [FP, 8] ; stream
  MOV A, B
  CALL fgetc
  MOV B, A
  ST.B [FP, 12], B ; c
  CMP.B B, 0
  JEQ .L106
  LD.B B, [FP, 12] ; c
  LD C, [FP, 13] ; cs
  ADD D, C, 1
  ST [FP, 13], D ; cs
  ST.B [C], B
  CMP.B B, '\0'
  JNE .L107
  JMP .L106
.L107:
  JMP .L105
.L106:
  LD B, [FP, 0] ; s
  JMP .L104
.L104:
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
  JMP .L108
.L108:
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
  JMP .L109
.L109:
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
  JMP .L110
.L110:
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
.L112:
  LD C, [FP, 0] ; s
  LD.B C, [C]
  CMP.B C, '\0'
  JEQ .L113
  LD C, [FP, 0] ; s
  LD.B C, [C]
  LD D, [FP, 4] ; stream
  MOV.B A, C
  MOV B, D
  CALL fputc
  LD C, [FP, 0] ; s
  ADD D, C, 1
  ST [FP, 0], D ; s
  JMP .L112
.L113:
  MOV C, 0
  JMP .L111
.L111:
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
  JMP .L114
.L114:
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
  JEQ .L115
  LD B, [FP, 0] ; n
  DIV B, 10
  MOV A, B
  CALL uprint
.L115:
  LD B, [FP, 0] ; n
  MOD B, 10
  ADD B, '0'
  MOV A, B
  CALL putchar
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
oprint:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  DIV B, 8
  CMP B, 0
  JEQ .L116
  LD B, [FP, 0] ; n
  DIV B, 8
  MOV A, B
  CALL oprint
.L116:
  LD B, [FP, 0] ; n
  MOD B, 8
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
  JGE .L117
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; n
  NEG B
  ST [FP, 0], B ; n
.L117:
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
  JEQ .L118
  LD C, [FP, 0] ; n
  DIV C, 16
  LD.B D, [FP, 4] ; uplo
  MOV A, C
  MOV.B B, D
  CALL xprint
.L118:
  LD C, [FP, 0] ; n
  MOD C, 16
  CMP C, 9
  JLS .L120
  LD C, [FP, 0] ; n
  MOD C, 16
  SUB C, 10
  LD.B D, [FP, 4] ; uplo
  ADD C, D
  MOV A, C
  CALL putchar
  JMP .L119
.L120:
  LD C, [FP, 0] ; n
  MOD C, 16
  ADD C, '0'
  MOV A, C
  CALL putchar
.L119:
  MOV SP, FP
  ADD SP, 5
  POP PC, C, D, FP
fprint:
  PUSH LR, C, FP
  SUB SP, 13
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD B, [FP, 0] ; f
  MOV C, 0
  ITF C, C
  CMPF B, C
  JGE .L121
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; f
  NEGF B
  ST [FP, 0], B ; f
.L121:
  LD B, [FP, 0] ; f
  FTI B, B
  ST [FP, 5], B ; left
  LD B, [FP, 5] ; left
  MOV A, B
  CALL uprint
  LD.B B, [FP, 4] ; prec
  CMP B, 0
  JLE .L122
  MOV.B B, '.'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; f
  LD C, [FP, 5] ; left
  ITF C, C
  SUBF B, C
  ST [FP, 9], B ; right
.L123:
  LD B, [FP, 9] ; right
  LDI C, 1092616192
  MULF B, C
  ST [FP, 9], B ; right
  LD B, [FP, 9] ; right
  FTI B, B
  ADD B, '0'
  MOV A, B
  CALL putchar
  LD B, [FP, 9] ; right
  LD C, [FP, 9] ; right
  FTI C, C
  ITF C, C
  SUBF B, C
  ST [FP, 9], B ; right
  LD.B B, [FP, 4] ; prec
  SUB.B B, 1
  ST.B [FP, 4], B ; prec
  CMP B, 0
  JGT .L123
.L124:
.L122:
  MOV SP, FP
  ADD SP, 13
  POP PC, C, FP
eprint:
  PUSH LR, C, D, FP
  SUB SP, 9
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD C, [FP, 0] ; f
  MOV D, 0
  ITF D, D
  CMPF C, D
  JGE .L125
  MOV.B C, '-'
  MOV.B A, C
  CALL putchar
  LD C, [FP, 0] ; f
  NEGF C
  ST [FP, 0], C ; f
.L125:
  MOV C, 0
  ST [FP, 5], C ; exp
  LD C, [FP, 0] ; f
  CMPF C, 0
  JEQ .L126
.L127:
  LD C, [FP, 0] ; f
  LDI D, 1092616192
  CMPF C, D
  JLT .L128
  LD C, [FP, 5] ; exp
  ADD D, C, 1
  ST [FP, 5], D ; exp
  LD C, [FP, 0] ; f
  LDI D, 1092616192
  DIVF C, D
  ST [FP, 0], C ; f
  JMP .L127
.L128:
.L129:
  LD C, [FP, 0] ; f
  LDI D, 1065353216
  CMPF C, D
  JGE .L130
  LD C, [FP, 5] ; exp
  SUB D, C, 1
  ST [FP, 5], D ; exp
  LD C, [FP, 0] ; f
  LDI D, 1092616192
  MULF C, D
  ST [FP, 0], C ; f
  JMP .L129
.L130:
.L126:
  LD C, [FP, 0] ; f
  LD.B D, [FP, 4] ; prec
  MOV A, C
  MOV.B B, D
  CALL fprint
  MOV.B C, 'e'
  MOV.B A, C
  CALL putchar
  LD C, [FP, 5] ; exp
  MOV A, C
  CALL dprint
  MOV SP, FP
  ADD SP, 9
  POP PC, C, D, FP
printf:
  PUSH D, C, B, A
  PUSH LR, E, FP
  SUB SP, 13
  MOV FP, SP
  ADD C, FP, 25
  MOV D, 1
  MUL D, 4
  ADD C, D
  ST [FP, 0], C ; ap
  MOV C, 0
  ST [FP, 8], C ; n
  LD C, [FP, 25] ; format
  ST [FP, 4], C ; c
.L131:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, 0
  JEQ .L133
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, '%'
  JNE .L135
  LD C, [FP, 4] ; c
  ADD D, C, 1
  ST [FP, 4], D ; c
  MOV C, 0
  ST.B [FP, 12], C ; precision
  MOV.B C, '0'
  LD D, [FP, 4] ; c
  LD.B D, [D]
  CMP.B C, D
  JGT .L136
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, '9'
  JGT .L136
  LD C, [FP, 4] ; c
  ADD D, C, 1
  ST [FP, 4], D ; c
  LD.B C, [C]
  SUB.B C, '0'
  ST.B [FP, 12], C ; precision
.L136:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B C, 'u'
  JEQ .L139
  CMP.B C, 'd'
  JEQ .L140
  CMP.B C, 'i'
  JEQ .L141
  CMP.B C, 'x'
  JEQ .L142
  CMP.B C, 'X'
  JEQ .L143
  CMP.B C, 'f'
  JEQ .L144
  CMP.B C, 'e'
  JEQ .L145
  CMP.B C, 's'
  JEQ .L146
  CMP.B C, 'c'
  JEQ .L147
  CMP.B C, 'o'
  JEQ .L148
  CMP.B C, 'n'
  JEQ .L149
  JMP .L150
.L139:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL uprint
  JMP .L138
.L140:
.L141:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL dprint
  JMP .L138
.L142:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV.B D, 'a'
  MOV A, C
  MOV.B B, D
  CALL xprint
  JMP .L138
.L143:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV.B D, 'A'
  MOV A, C
  MOV.B B, D
  CALL xprint
  JMP .L138
.L144:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  LD.B D, [FP, 12] ; precision
  MOV A, C
  MOV.B B, D
  CALL fprint
  JMP .L138
.L145:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  LD.B D, [FP, 12] ; precision
  MOV A, C
  MOV.B B, D
  CALL eprint
  JMP .L138
.L146:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL printf
  JMP .L138
.L147:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
  JMP .L138
.L148:
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  MOV A, C
  CALL oprint
  JMP .L138
.L149:
  LD C, [FP, 8] ; n
  LD D, [FP, 0] ; ap
  ADD E, D, 4
  ST [FP, 0], E ; ap
  LD D, [D]
  ST [D], C
  JMP .L138
.L150:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
.L138:
  JMP .L134
.L135:
  LD C, [FP, 4] ; c
  LD.B C, [C]
  MOV.B A, C
  CALL putchar
.L134:
.L132:
  LD C, [FP, 4] ; c
  ADD D, C, 1
  ST [FP, 4], D ; c
  LD C, [FP, 8] ; n
  ADD D, C, 1
  ST [FP, 8], D ; n
  JMP .L131
.L133:
  MOV C, 0
  ST [FP, 0], C ; ap
  MOV SP, FP
  ADD SP, 13
  POP LR, E, FP
  ADD SP, 16
  RET
initVector:
  PUSH LR, B, C, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  MOV B, 0
  LD C, [FP, 0] ; vector
  ST [C, 0], B ; size
  MOV B, 8
  LD C, [FP, 0] ; vector
  ST [C, 4], B ; capacity
  LD B, [FP, 0] ; vector
  LD B, [B, 4] ; capacity
  MUL B, 4
  MOV A, B
  CALL malloc
  MOV B, A
  LD C, [FP, 0] ; vector
  ST [C, 8], B ; data
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, FP
freeVector:
  PUSH LR, B, C, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  MOV B, 0
  ST [FP, 4], B ; i
.L151:
  LD B, [FP, 4] ; i
  LD C, [FP, 0] ; vector
  LD C, [C, 0] ; size
  CMP B, C
  JCS .L153
  LD B, [FP, 0] ; vector
  LD B, [B, 8] ; data
  LD C, [FP, 4] ; i
  MUL C, 4
  ADD B, C
  LD B, [B]
  MOV A, B
  CALL free
.L152:
  LD B, [FP, 4] ; i
  ADD C, B, 1
  ST [FP, 4], C ; i
  JMP .L151
.L153:
  LD B, [FP, 0] ; vector
  LD B, [B, 8] ; data
  MOV A, B
  CALL free
  LD B, [FP, 0] ; vector
  MOV A, B
  CALL free
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, FP
get:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 4] ; index
  LD B, [FP, 0] ; vector
  LD B, [B, 4] ; capacity
  CMP A, B
  JCC .L155
  MOV A, 0
  JMP .L154
.L155:
  LD A, [FP, 0] ; vector
  LD A, [A, 8] ; data
  LD B, [FP, 4] ; index
  MUL B, 4
  ADD A, B
  LD A, [A]
  JMP .L154
.L154:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
set:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 4] ; index
  LD B, [FP, 0] ; vector
  LD B, [B, 4] ; capacity
  CMP A, B
  JCS .L156
  LD A, [FP, 8] ; value
  LD B, [FP, 0] ; vector
  LD B, [B, 8] ; data
  LD C, [FP, 4] ; index
  MUL C, 4
  ADD B, C
  ST [B], A
.L156:
  MOV SP, FP
  ADD SP, 12
  POP FP
  RET
push:
  PUSH LR, C, D, E, F, G, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD C, [FP, 0] ; vector
  LD C, [C, 0] ; size
  LD D, [FP, 0] ; vector
  LD D, [D, 4] ; capacity
  CMP C, D
  JNE .L158
  LD C, [FP, 0] ; vector
  LD C, [C, 4] ; capacity
  MUL C, 2
  LD D, [FP, 0] ; vector
  ST [D, 4], C ; capacity
  LD C, [FP, 0] ; vector
  LD C, [C, 8] ; data
  LD D, [FP, 0] ; vector
  LD D, [D, 4] ; capacity
  MUL D, 4
  MOV A, C
  MOV B, D
  CALL realloc
  MOV C, A
  LD D, [FP, 0] ; vector
  ST [D, 8], C ; data
.L158:
  LD C, [FP, 4] ; value
  LD D, [FP, 0] ; vector
  LD D, [D, 8] ; data
  LD E, [FP, 0] ; vector
  LD E, [E, 0] ; size
  ADD F, E, 1
  LD G, [FP, 0] ; vector
  ST [G, 0], F ; size
  MUL E, 4
  ADD D, E
  ST [D], C
  LD C, [FP, 0] ; vector
  LD C, [C, 0] ; size
  JMP .L157
.L157:
  MOV A, C
  MOV SP, FP
  ADD SP, 8
  POP PC, C, D, E, F, G, FP
pop:
  PUSH LR, B, C, D, E, F, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LD C, [FP, 0] ; vector
  LD C, [C, 0] ; size
  CMP C, 0
  JNE .L160
  MOV C, 0
  JMP .L159
.L160:
  LD C, [FP, 0] ; vector
  LD C, [C, 8] ; data
  LD D, [FP, 0] ; vector
  LD D, [D, 0] ; size
  SUB E, D, 1
  LD F, [FP, 0] ; vector
  ST [F, 0], E ; size
  MUL D, 4
  ADD C, D
  LD C, [C]
  ST [FP, 4], C ; ret
  LD C, [FP, 0] ; vector
  LD C, [C, 0] ; size
  CMP C, 8
  JLS .L161
  LD C, [FP, 0] ; vector
  LD C, [C, 4] ; capacity
  DIV C, 2
  LD D, [FP, 0] ; vector
  ST [D, 4], C ; capacity
  LD C, [FP, 0] ; vector
  LD C, [C, 8] ; data
  LD D, [FP, 0] ; vector
  LD D, [D, 4] ; capacity
  MUL D, 4
  MOV A, C
  MOV B, D
  CALL realloc
  MOV C, A
  LD D, [FP, 0] ; vector
  ST [D, 8], C ; data
.L161:
  LD C, [FP, 4] ; ret
  JMP .L159
.L159:
  MOV A, C
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, D, E, F, FP
iter:
  PUSH LR, C, FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  MOV B, 0
  ST [FP, 8], B ; i
.L162:
  LD B, [FP, 8] ; i
  LD C, [FP, 0] ; vector
  LD C, [C, 0] ; size
  CMP B, C
  JCS .L164
  LD B, [FP, 0] ; vector
  LD B, [B, 8] ; data
  LD C, [FP, 8] ; i
  MUL C, 4
  ADD B, C
  LD B, [B]
  MOV A, B
  LD B, [FP, 4] ; f
  CALL B
.L163:
  LD B, [FP, 8] ; i
  ADD C, B, 1
  ST [FP, 8], C ; i
  JMP .L162
.L164:
  MOV SP, FP
  ADD SP, 12
  POP PC, C, FP
split:
  PUSH LR, B, C, D, E, F, FP
  SUB SP, 52
  MOV FP, SP
  ST [FP, 0], A
  MOV C, 12
  MOV A, C
  CALL malloc
  MOV C, A
  ST [FP, 4], C ; vector
  LD C, [FP, 4] ; vector
  MOV A, C
  CALL initVector
  MOV C, 0
  ST [FP, 44], C ; b
  LD C, [FP, 0] ; str
  MOV A, C
  CALL strlen
  MOV C, A
  ST [FP, 48], C ; n
  MOV C, 0
  ST [FP, 40], C ; i
.L166:
  LD C, [FP, 40] ; i
  LD D, [FP, 48] ; n
  CMP C, D
  JCS .L168
  LD C, [FP, 0] ; str
  LD D, [FP, 40] ; i
  ADD C, D
  LD.B C, [C]
  CMP.B C, ' '
  JEQ .L171
  CMP.B C, '\t'
  JEQ .L172
  JMP .L173
.L171:
.L172:
  MOV.B C, '\0'
  ADD D, FP, 8
  LD E, [FP, 44] ; b
  ADD D, E
  ST.B [D], C
  LD C, [FP, 4] ; vector
  ADD D, FP, 8
  MOV A, D
  CALL strdup
  MOV D, A
  MOV A, C
  MOV B, D
  CALL push
  MOV.B C, '\0'
  ADD D, FP, 8
  MOV E, 0
  ST [FP, 44], E ; b
  ADD D, E
  ST.B [D], C
  JMP .L170
.L173:
  LD C, [FP, 0] ; str
  LD D, [FP, 40] ; i
  ADD C, D
  LD.B C, [C]
  ADD D, FP, 8
  LD E, [FP, 44] ; b
  ADD F, E, 1
  ST [FP, 44], F ; b
  ADD D, E
  ST.B [D], C
.L170:
.L167:
  LD C, [FP, 40] ; i
  ADD D, C, 1
  ST [FP, 40], D ; i
  JMP .L166
.L168:
  LD C, [FP, 44] ; b
  CMP C, 0
  JLS .L174
  MOV.B C, '\0'
  ADD D, FP, 8
  LD E, [FP, 44] ; b
  ADD D, E
  ST.B [D], C
  LD C, [FP, 4] ; vector
  ADD D, FP, 8
  MOV A, D
  CALL strdup
  MOV D, A
  MOV A, C
  MOV B, D
  CALL push
.L174:
  LD C, [FP, 4] ; vector
  JMP .L165
.L165:
  MOV A, C
  MOV SP, FP
  ADD SP, 52
  POP PC, B, C, D, E, F, FP
print:
  PUSH LR, B, C, D, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LDI C, =.S0
  LD D, [FP, 0] ; s
  MOV A, C
  MOV B, D
  CALL printf
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, D, FP
main:
  PUSH LR, B, C, D, FP
  SUB SP, 4
  MOV FP, SP
  LDI C, =.S1
  MOV A, C
  CALL split
  MOV C, A
  ST [FP, 0], C ; v
  LD C, [FP, 0] ; v
  LDI D, =print
  MOV A, C
  MOV B, D
  CALL iter
  LD C, [FP, 0] ; v
  MOV A, C
  CALL freeVector
  MOV C, 0
  JMP .L175
.L175:
  MOV A, C
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, D, FP