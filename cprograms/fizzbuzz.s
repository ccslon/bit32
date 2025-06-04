next_rand: .word 0
heapindex: .word 0
.S0: "fizz\0"
.S1: "buzz\0"
.S2: "%s\n\0"
.S3: "%d\n\0"
strlen:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 0
  ST [FP, 4], A ; l
.L1:
  LD A, [FP, 0] ; s
  LD B, [FP, 4] ; l
  ADD A, B
  LD.B A, [A]
  CMP.B A, '\0'
  JEQ .L2
  LD A, [FP, 4] ; l
  ADD B, A, 1
  ST [FP, 4], B ; l
  JMP .L1
.L2:
  LD A, [FP, 4] ; l
  JMP .L0
.L0:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
strcpy:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  MOV A, 0
  ST [FP, 8], A ; i
.L4:
  LD A, [FP, 4] ; t
  LD B, [FP, 8] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 8] ; i
  ADD B, C
  ST.B [B], A
  CMP.B A, '\0'
  JEQ .L6
.L5:
  LD A, [FP, 8] ; i
  ADD B, A, 1
  ST [FP, 8], B ; i
  JMP .L4
.L6:
  LD A, [FP, 0] ; s
  JMP .L3
.L3:
  MOV SP, FP
  ADD SP, 12
  POP FP
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
.L8:
  LD A, [FP, 12] ; i
  LD B, [FP, 8] ; n
  CMP A, B
  JCS .L10
  LD A, [FP, 4] ; t
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 12] ; i
  ADD B, C
  ST.B [B], A
  CMP.B A, '\0'
  JEQ .L10
.L9:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L8
.L10:
  LD A, [FP, 0] ; s
  JMP .L7
.L7:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
strdup:
  PUSH LR, E, F, G, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; s
  CALL strlen
  MOV E, A
  ADD E, 1
  MOV A, E
  CALL malloc
  MOV E, A
  ST [FP, 4], E ; p
  LD A, [FP, 4] ; p
  MOV B, 0
  CMP A, B
  JEQ .L12
  LD E, [FP, 4] ; p
  LD F, [FP, 0] ; s
  LD A, [FP, 0] ; s
  CALL strlen
  MOV G, A
  ADD G, 1
  MOV A, E
  MOV B, F
  MOV C, G
  CALL strncpy
.L12:
  LD A, [FP, 4] ; p
  JMP .L11
.L11:
  MOV SP, FP
  ADD SP, 8
  POP PC, E, F, G, FP
strcat:
  PUSH LR, FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; s
  CALL strlen
  ST [FP, 8], A ; i
  MOV A, 0
  ST [FP, 12], A ; j
.L14:
  LD A, [FP, 4] ; t
  LD A, [FP, 12] ; j
  ADD B, A, 1
  ST [FP, 12], B ; j
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; s
  LD A, [FP, 8] ; i
  ADD B, A, 1
  ST [FP, 8], B ; i
  ADD B, C
  ST.B [B], A
  CMP.B A, '\0'
  JEQ .L15
  JMP .L14
.L15:
  LD A, [FP, 0] ; s
  JMP .L13
.L13:
  MOV SP, FP
  ADD SP, 16
  POP PC, FP
strrev:
  PUSH LR, E, FP
  SUB SP, 13
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 0
  ST [FP, 4], A ; front
  LD A, [FP, 0] ; s
  CALL strlen
  MOV E, A
  SUB E, 1
  ST [FP, 8], E ; back
.L17:
  LD A, [FP, 4] ; front
  LD B, [FP, 8] ; back
  CMP A, B
  JCS .L19
  LD A, [FP, 0] ; s
  LD B, [FP, 4] ; front
  ADD A, B
  LD.B A, [A]
  ST.B [FP, 12], A ; temp
  LD A, [FP, 0] ; s
  LD B, [FP, 8] ; back
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 4] ; front
  ADD B, C
  ST.B [B], A
  LD.B A, [FP, 12] ; temp
  LD B, [FP, 0] ; s
  LD C, [FP, 8] ; back
  ADD B, C
  ST.B [B], A
.L18:
  LD A, [FP, 4] ; front
  ADD B, A, 1
  ST [FP, 4], B ; front
  LD A, [FP, 8] ; back
  SUB B, A, 1
  ST [FP, 8], B ; back
  JMP .L17
.L19:
  LD A, [FP, 0] ; s
  JMP .L16
.L16:
  MOV SP, FP
  ADD SP, 13
  POP PC, E, FP
strcmp:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  MOV A, 0
  ST [FP, 8], A ; i
.L21:
  LD A, [FP, 0] ; s
  LD B, [FP, 8] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 8] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JNE .L23
  LD A, [FP, 0] ; s
  LD B, [FP, 8] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '\0'
  JNE .L24
  MOV A, 0
  JMP .L20
.L24:
.L22:
  LD A, [FP, 8] ; i
  ADD B, A, 1
  ST [FP, 8], B ; i
  JMP .L21
.L23:
  LD A, [FP, 0] ; s
  LD B, [FP, 8] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 8] ; i
  ADD B, C
  LD.B B, [B]
  SUB A, B
  JMP .L20
.L20:
  MOV SP, FP
  ADD SP, 12
  POP FP
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
.L26:
  LD A, [FP, 12] ; i
  LD B, [FP, 8] ; n
  CMP A, B
  JCS .L28
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JNE .L28
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '\0'
  JNE .L29
  MOV A, 0
  JMP .L25
.L29:
.L27:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L26
.L28:
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  SUB A, B
  JMP .L25
.L25:
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
.L31:
  LD A, [FP, 0] ; s
  LD B, [FP, 5] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '\0'
  JEQ .L33
  LD A, [FP, 0] ; s
  LD B, [FP, 5] ; i
  ADD A, B
  LD.B A, [A]
  LD.B B, [FP, 4] ; c
  CMP.B A, B
  JNE .L34
  LD A, [FP, 0] ; s
  LD B, [FP, 5] ; i
  ADD A, B
  JMP .L30
.L34:
.L32:
  LD A, [FP, 5] ; i
  ADD B, A, 1
  ST [FP, 5], B ; i
  JMP .L31
.L33:
  MOV A, 0
  JMP .L30
.L30:
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
.L36:
  LD A, [FP, 9] ; i
  LD B, [FP, 5] ; n
  CMP A, B
  JCS .L38
  LD.B A, [FP, 4] ; v
  LD B, [FP, 0] ; s
  LD C, [FP, 9] ; i
  ADD B, C
  ST.B [B], A
.L37:
  LD A, [FP, 9] ; i
  ADD B, A, 1
  ST [FP, 9], B ; i
  JMP .L36
.L38:
  LD A, [FP, 0] ; s
  JMP .L35
.L35:
  MOV SP, FP
  ADD SP, 13
  POP FP
  RET
memcpy:
  PUSH FP
  SUB SP, 22
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 8] ; n
  DIV A, 4
  ST [FP, 12], A ; words
  LD A, [FP, 8] ; n
  MOD A, 4
  ST.B [FP, 16], A ; tail
  MOV A, 0
  ST [FP, 17], A ; i
.L40:
  LD A, [FP, 17] ; i
  LD B, [FP, 12] ; words
  CMP A, B
  JCS .L42
  LD A, [FP, 4] ; t
  LD B, [FP, 17] ; i
  MUL B, 4
  ADD A, B
  LD A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 17] ; i
  MUL C, 4
  ADD B, C
  ST [B], A
.L41:
  LD A, [FP, 17] ; i
  ADD B, A, 1
  ST [FP, 17], B ; i
  JMP .L40
.L42:
  MOV A, 0
  ST.B [FP, 21], A ; c
.L43:
  LD.B A, [FP, 21] ; c
  LD.B B, [FP, 16] ; tail
  CMP.B A, B
  JGE .L45
  LD A, [FP, 4] ; t
  LD B, [FP, 17] ; i
  ADD A, B
  LD.B B, [FP, 21] ; c
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; s
  LD C, [FP, 17] ; i
  ADD B, C
  LD.B C, [FP, 21] ; c
  ADD B, C
  ST.B [B], A
.L44:
  LD.B A, [FP, 21] ; c
  ADD.B B, A, 1
  ST.B [FP, 21], B ; c
  JMP .L43
.L45:
  LD A, [FP, 0] ; s
  JMP .L39
.L39:
  MOV SP, FP
  ADD SP, 22
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
.L47:
  LD A, [FP, 12] ; i
  LD B, [FP, 8] ; n
  CMP A, B
  JCS .L49
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JEQ .L50
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 4] ; t
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  SUB A, B
  JMP .L46
.L50:
.L48:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L47
.L49:
  MOV A, 0
  JMP .L46
.L46:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
div:
  PUSH FP
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
  JMP .L51
.L51:
  MOV SP, FP
  ADD SP, 16
  POP FP
  RET
abs:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; n
  CMP A, 0
  JGE .L53
  LD A, [FP, 0] ; n
  NEG A
  JMP .L52
.L53:
  LD A, [FP, 0] ; n
  JMP .L52
.L52:
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET
bsearch:
  PUSH LR, FP
  SUB SP, 32
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  MOV A, 0
  ST [FP, 16], A ; low
  LD A, [FP, 12] ; n
  SUB A, 1
  ST [FP, 24], A ; high
.L55:
  LD A, [FP, 16] ; low
  LD B, [FP, 24] ; high
  CMP A, B
  JGT .L56
  LD A, [FP, 16] ; low
  LD B, [FP, 24] ; high
  LD C, [FP, 16] ; low
  SUB B, C
  DIV B, 2
  ADD A, B
  ST [FP, 20], A ; mid
  LD A, [FP, 0] ; x
  LD B, [FP, 4] ; v
  LD C, [FP, 20] ; mid
  LD D, [FP, 8] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 40] ; cmp
  CALL C
  ST [FP, 28], A ; cond
  LD A, [FP, 28] ; cond
  CMP A, 0
  JGE .L58
  LD A, [FP, 20] ; mid
  SUB A, 1
  ST [FP, 24], A ; high
  JMP .L57
.L58:
  LD A, [FP, 28] ; cond
  CMP A, 0
  JLE .L59
  LD A, [FP, 20] ; mid
  ADD A, 1
  ST [FP, 16], A ; low
  JMP .L57
.L59:
  LD A, [FP, 20] ; mid
  LD B, [FP, 8] ; size
  MUL A, B
  JMP .L54
.L57:
  JMP .L55
.L56:
  MVN A, 1
  JMP .L54
.L54:
  MOV SP, FP
  ADD SP, 32
  POP PC, FP
swap:
  PUSH FP
  SUB SP, 30
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
  ST.B [FP, 20], A ; tail
  MOV A, 0
  ST [FP, 25], A ; k
.L60:
  LD A, [FP, 25] ; k
  LD B, [FP, 16] ; words
  CMP A, B
  JCS .L62
  LD A, [FP, 0] ; v
  LD B, [FP, 8] ; i
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 25] ; k
  ADD A, B
  LD A, [A]
  ST [FP, 21], A ; t
  LD A, [FP, 0] ; v
  LD B, [FP, 12] ; j
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 25] ; k
  ADD A, B
  LD A, [A]
  LD B, [FP, 0] ; v
  LD C, [FP, 8] ; i
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 25] ; k
  ADD B, C
  ST [B], A
  LD A, [FP, 21] ; t
  LD B, [FP, 0] ; v
  LD C, [FP, 12] ; j
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 25] ; k
  ADD B, C
  ST [B], A
.L61:
  LD A, [FP, 25] ; k
  ADD A, 4
  ST [FP, 25], A ; k
  JMP .L60
.L62:
  MOV A, 0
  ST.B [FP, 29], A ; c
.L63:
  LD.B A, [FP, 29] ; c
  LD.B B, [FP, 20] ; tail
  CMP.B A, B
  JGE .L65
  LD A, [FP, 0] ; v
  LD B, [FP, 8] ; i
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 25] ; k
  ADD A, B
  LD.B B, [FP, 29] ; c
  ADD A, B
  LD.B A, [A]
  ST [FP, 21], A ; t
  LD A, [FP, 0] ; v
  LD B, [FP, 12] ; j
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 25] ; k
  ADD A, B
  LD.B B, [FP, 29] ; c
  ADD A, B
  LD.B A, [A]
  LD B, [FP, 0] ; v
  LD C, [FP, 8] ; i
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 25] ; k
  ADD B, C
  LD.B C, [FP, 29] ; c
  ADD B, C
  ST.B [B], A
  LD A, [FP, 21] ; t
  LD B, [FP, 0] ; v
  LD C, [FP, 12] ; j
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 25] ; k
  ADD B, C
  LD.B C, [FP, 29] ; c
  ADD B, C
  ST.B [B], A
.L64:
  LD.B A, [FP, 29] ; c
  ADD.B B, A, 1
  ST.B [FP, 29], B ; c
  JMP .L63
.L65:
  MOV SP, FP
  ADD SP, 30
  POP FP
  RET
qsort:
  PUSH LR, E, F, FP
  SUB SP, 24
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  ST [FP, 12], D
  LD A, [FP, 8] ; left
  LD B, [FP, 12] ; right
  CMP A, B
  JLT .L67
  JMP .L66
.L67:
  LD A, [FP, 0] ; v
  LD B, [FP, 4] ; size
  LD C, [FP, 8] ; left
  LD D, [FP, 8] ; left
  LD E, [FP, 12] ; right
  LD F, [FP, 8] ; left
  SUB E, F
  DIV E, 2
  ADD D, E
  CALL swap
  LD A, [FP, 8] ; left
  ST [FP, 20], A ; last
  LD A, [FP, 8] ; left
  ADD A, 1
  ST [FP, 16], A ; i
.L68:
  LD A, [FP, 16] ; i
  LD B, [FP, 12] ; right
  CMP A, B
  JGT .L70
  LD A, [FP, 0] ; v
  LD B, [FP, 16] ; i
  LD C, [FP, 4] ; size
  MUL B, C
  ADD A, B
  LD B, [FP, 0] ; v
  LD C, [FP, 8] ; left
  LD D, [FP, 4] ; size
  MUL C, D
  ADD B, C
  LD C, [FP, 40] ; cmp
  CALL C
  CMP A, 0
  JGE .L71
  LD A, [FP, 0] ; v
  LD B, [FP, 4] ; size
  LD A, [FP, 20] ; last
  ADD A, 1
  ST [FP, 20], A ; last
  LD D, [FP, 16] ; i
  CALL swap
.L71:
.L69:
  LD A, [FP, 16] ; i
  ADD B, A, 1
  ST [FP, 16], B ; i
  JMP .L68
.L70:
  LD A, [FP, 0] ; v
  LD B, [FP, 4] ; size
  LD C, [FP, 8] ; left
  LD D, [FP, 20] ; last
  CALL swap
  LD A, [FP, 0] ; v
  LD B, [FP, 4] ; size
  LD C, [FP, 8] ; left
  LD D, [FP, 20] ; last
  SUB D, 1
  LD E, [FP, 40] ; cmp
  CALL qsort
  LD A, [FP, 0] ; v
  LD B, [FP, 4] ; size
  LD C, [FP, 20] ; last
  ADD C, 1
  LD D, [FP, 12] ; right
  LD E, [FP, 40] ; cmp
  CALL qsort
.L66:
  MOV SP, FP
  ADD SP, 24
  POP PC, E, F, FP
rand:
  PUSH FP
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
  JMP .L72
.L72:
  MOV SP, FP
  POP FP
  RET
srand:
  PUSH FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; seed
  LDI B, =next_rand
  ST [B], A
  MOV SP, FP
  ADD SP, 4
  POP FP
  RET
atoi:
  PUSH FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 0
  ST [FP, 8], A ; n
  MOV A, 0
  ST [FP, 4], A ; i
.L74:
  MOV.B A, '0'
  LD B, [FP, 0] ; s
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JGT .L76
  LD A, [FP, 0] ; s
  LD B, [FP, 4] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '9'
  JGT .L76
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
.L75:
  LD A, [FP, 4] ; i
  ADD A, 1
  ST [FP, 4], A ; i
  JMP .L74
.L76:
  LD A, [FP, 8] ; n
  JMP .L73
.L73:
  MOV SP, FP
  ADD SP, 12
  POP FP
  RET
atof:
  PUSH E, F, FP
  SUB SP, 20
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 0
  ST [FP, 12], A ; i
  LD E, [FP, 0] ; s
  LD F, [FP, 12] ; i
  ADD E, F
  LD.B E, [E]
  CMP.B E, '-'
  JNE .L79
  MVN E, 1
  JMP .L78
.L79:
  MOV E, 1
.L78:
  ST [FP, 16], E ; sign
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '+'
  JEQ .L81
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '-'
  JNE .L80
.L81:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
.L80:
  LDI A, 0
  ST [FP, 4], A ; val
.L82:
  MOV.B A, '0'
  LD B, [FP, 0] ; s
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JGT .L84
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '9'
  JGT .L84
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
.L83:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L82
.L84:
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '.'
  JNE .L85
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
.L85:
  LDI A, 1065353216
  ST [FP, 8], A ; pow
.L86:
  MOV.B A, '0'
  LD B, [FP, 0] ; s
  LD C, [FP, 12] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B A, B
  JGT .L88
  LD A, [FP, 0] ; s
  LD B, [FP, 12] ; i
  ADD A, B
  LD.B A, [A]
  CMP.B A, '9'
  JGT .L88
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
.L87:
  LD A, [FP, 12] ; i
  ADD B, A, 1
  ST [FP, 12], B ; i
  JMP .L86
.L88:
  LD A, [FP, 16] ; sign
  ITF A, A
  LD B, [FP, 4] ; val
  MULF A, B
  LD B, [FP, 8] ; pow
  DIVF A, B
  JMP .L77
.L77:
  MOV SP, FP
  ADD SP, 20
  POP E, F, FP
  RET
malloc:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LDI A, =stdheap
  LDI B, =heapindex
  LD B, [B]
  ADD A, B
  ST [FP, 4], A ; ptr
  LDI A, =heapindex
  LD A, [A]
  LD B, [FP, 0] ; bytes
  ADD A, B
  LDI B, =heapindex
  ST [B], A
  LD A, [FP, 4] ; ptr
  JMP .L89
.L89:
  MOV SP, FP
  ADD SP, 8
  POP FP
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
  PUSH LR, FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 4] ; size
  CALL malloc
  ST [FP, 8], A ; d
  LD A, [FP, 8] ; d
  LD B, [FP, 0] ; p
  LD C, [FP, 4] ; size
  CALL memcpy
  LD A, [FP, 0] ; p
  CALL free
  LD A, [FP, 8] ; d
  JMP .L90
.L90:
  MOV SP, FP
  ADD SP, 12
  POP PC, FP
calloc:
  PUSH LR, FP
  SUB SP, 32
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; n
  LD B, [FP, 4] ; size
  MUL A, B
  ST [FP, 8], A ; bytes
  LD A, [FP, 8] ; bytes
  DIV A, 4
  ST [FP, 12], A ; words
  LD A, [FP, 8] ; bytes
  MOD A, 4
  ST [FP, 16], A ; tail
  LD A, [FP, 8] ; bytes
  CALL malloc
  ST [FP, 24], A ; p
  MOV A, 0
  ST [FP, 20], A ; i
.L92:
  LD A, [FP, 20] ; i
  LD B, [FP, 12] ; words
  CMP A, B
  JCS .L94
  MOV A, 0
  LD B, [FP, 24] ; p
  LD C, [FP, 20] ; i
  ADD B, C
  ST [B], A
.L93:
  LD A, [FP, 20] ; i
  ADD B, A, 1
  ST [FP, 20], B ; i
  JMP .L92
.L94:
  MOV A, 0
  ST [FP, 28], A ; c
.L95:
  LD A, [FP, 28] ; c
  LD B, [FP, 16] ; tail
  CMP A, B
  JCS .L97
  MOV A, 0
  LD B, [FP, 24] ; p
  LD C, [FP, 20] ; i
  ADD B, C
  LD C, [FP, 28] ; c
  ADD B, C
  ST.B [B], A
.L96:
  LD A, [FP, 28] ; c
  ADD B, A, 1
  ST [FP, 28], B ; c
  JMP .L95
.L97:
  LD A, [FP, 24] ; p
  JMP .L91
.L91:
  MOV SP, FP
  ADD SP, 32
  POP PC, FP
fgetc:
  PUSH FP
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
  POP FP
  RET
getchar:
  PUSH FP
  SUB SP, 1
  MOV FP, SP
.L102:
  LDI A, =stdin
  LD A, [A]
  LD A, [A, 4] ; read
  LDI B, =stdin
  LD B, [B]
  LD B, [B, 8] ; write
  CMP A, B
  JNE .L103
  JMP .L102
.L103:
  LDI A, =stdin
  LD A, [A]
  LD A, [A, 0] ; buffer
  LDI B, =stdin
  LD B, [B]
  LD B, [B, 4] ; read
  ADD A, B
  LD.B A, [A]
  ST.B [FP, 0], A ; c
  LDI A, =stdin
  LD A, [A]
  LD A, [A, 4] ; read
  ADD A, 1
  LDI B, =stdin
  LD B, [B]
  LD B, [B, 12] ; size
  MOD A, B
  LDI B, =stdin
  LD B, [B]
  ST [B, 4], A ; read
  LD.B A, [FP, 0] ; c
  JMP .L101
.L101:
  MOV SP, FP
  ADD SP, 1
  POP FP
  RET
fgets:
  PUSH LR, FP
  SUB SP, 17
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  LD A, [FP, 0] ; s
  ST [FP, 13], A ; cs
.L105:
  LD A, [FP, 4] ; n
  SUB A, 1
  ST [FP, 4], A ; n
  CMP A, 0
  JLS .L106
  LD A, [FP, 8] ; stream
  CALL fgetc
  ST.B [FP, 12], A ; c
  CMP.B A, 0
  JEQ .L106
  LD.B A, [FP, 12] ; c
  LD A, [FP, 13] ; cs
  ADD B, A, 1
  ST [FP, 13], B ; cs
  ST.B [B], A
  JMP .L105
.L106:
  MOV.B A, '\0'
  LD B, [FP, 13] ; cs
  ST.B [B], A
  LD A, [FP, 0] ; s
  JMP .L104
.L104:
  MOV SP, FP
  ADD SP, 17
  POP PC, FP
gets:
  PUSH LR, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; s
  LD B, [FP, 4] ; n
  LDI C, =stdin
  LD C, [C]
  CALL fgets
  JMP .L107
.L107:
  MOV SP, FP
  ADD SP, 8
  POP PC, FP
fputc:
  PUSH FP
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
  JMP .L108
.L108:
  MOV SP, FP
  ADD SP, 5
  POP FP
  RET
putchar:
  PUSH FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B A, [FP, 0] ; c
  LDI B, =stdout
  LD B, [B]
  LD B, [B, 0] ; buffer
  LDI C, =stdout
  LD C, [C]
  LD C, [C, 8] ; write
  ADD B, C
  ST.B [B], A
  MOV A, 0
  JMP .L109
.L109:
  MOV SP, FP
  ADD SP, 1
  POP FP
  RET
fputs:
  PUSH LR, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
.L111:
  LD A, [FP, 0] ; s
  LD.B A, [A]
  CMP.B A, '\0'
  JEQ .L112
  LD A, [FP, 0] ; s
  LD.B A, [A]
  LD B, [FP, 4] ; stream
  CALL fputc
  LD A, [FP, 0] ; s
  ADD B, A, 1
  ST [FP, 0], B ; s
  JMP .L111
.L112:
  MOV A, 0
  JMP .L110
.L110:
  MOV SP, FP
  ADD SP, 8
  POP PC, FP
puts:
  PUSH LR, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; s
  LDI B, =stdout
  LD B, [B]
  CALL fputs
  MOV.B A, '\n'
  CALL putchar
  MOV A, 0
  JMP .L113
.L113:
  MOV SP, FP
  ADD SP, 4
  POP PC, FP
uprint:
  PUSH LR, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; n
  DIV A, 10
  CMP A, 0
  JEQ .L114
  LD A, [FP, 0] ; n
  DIV A, 10
  CALL uprint
.L114:
  LD A, [FP, 0] ; n
  MOD A, 10
  ADD A, '0'
  CALL putchar
  MOV SP, FP
  ADD SP, 4
  POP PC, FP
oprint:
  PUSH LR, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; n
  DIV A, 8
  CMP A, 0
  JEQ .L115
  LD A, [FP, 0] ; n
  DIV A, 8
  CALL oprint
.L115:
  LD A, [FP, 0] ; n
  MOD A, 8
  ADD A, '0'
  CALL putchar
  MOV SP, FP
  ADD SP, 4
  POP PC, FP
dprint:
  PUSH LR, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD A, [FP, 0] ; n
  CMP A, 0
  JGE .L116
  MOV.B A, '-'
  CALL putchar
  LD A, [FP, 0] ; n
  NEG A
  ST [FP, 0], A ; n
.L116:
  LD A, [FP, 0] ; n
  CALL uprint
  MOV SP, FP
  ADD SP, 4
  POP PC, FP
xprint:
  PUSH LR, FP
  SUB SP, 5
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD A, [FP, 0] ; n
  DIV A, 16
  CMP A, 0
  JEQ .L117
  LD A, [FP, 0] ; n
  DIV A, 16
  LD.B B, [FP, 4] ; uplo
  CALL xprint
.L117:
  LD A, [FP, 0] ; n
  MOD A, 16
  CMP A, 9
  JLS .L119
  LD A, [FP, 0] ; n
  MOD A, 16
  SUB A, 10
  LD.B B, [FP, 4] ; uplo
  ADD A, B
  CALL putchar
  JMP .L118
.L119:
  LD A, [FP, 0] ; n
  MOD A, 16
  ADD A, '0'
  CALL putchar
.L118:
  MOV SP, FP
  ADD SP, 5
  POP PC, FP
fprint:
  PUSH LR, FP
  SUB SP, 13
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD A, [FP, 0] ; f
  MOV B, 0
  ITF B, B
  CMPF A, B
  JGE .L120
  MOV.B A, '-'
  CALL putchar
  LD A, [FP, 0] ; f
  NEGF A
  ST [FP, 0], A ; f
.L120:
  LD A, [FP, 0] ; f
  FTI A, A
  ST [FP, 5], A ; left
  LD A, [FP, 5] ; left
  CALL uprint
  LD.B A, [FP, 4] ; prec
  CMP A, 0
  JLE .L121
  MOV.B A, '.'
  CALL putchar
  LD A, [FP, 0] ; f
  LD B, [FP, 5] ; left
  ITF B, B
  SUBF A, B
  ST [FP, 9], A ; right
.L122:
  LD A, [FP, 9] ; right
  LDI B, 1092616192
  MULF A, B
  ST [FP, 9], A ; right
  LD A, [FP, 9] ; right
  FTI A, A
  ADD A, '0'
  CALL putchar
  LD A, [FP, 9] ; right
  LD B, [FP, 9] ; right
  FTI B, B
  ITF B, B
  SUBF A, B
  ST [FP, 9], A ; right
  LD.B A, [FP, 4] ; prec
  SUB.B A, 1
  ST.B [FP, 4], A ; prec
  CMP A, 0
  JGT .L122
.L123:
.L121:
  MOV SP, FP
  ADD SP, 13
  POP PC, FP
eprint:
  PUSH LR, FP
  SUB SP, 9
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD A, [FP, 0] ; f
  MOV B, 0
  ITF B, B
  CMPF A, B
  JGE .L124
  MOV.B A, '-'
  CALL putchar
  LD A, [FP, 0] ; f
  NEGF A
  ST [FP, 0], A ; f
.L124:
  MOV A, 0
  ST [FP, 5], A ; exp
  LD A, [FP, 0] ; f
  CMPF A, 0
  JEQ .L125
.L126:
  LD A, [FP, 0] ; f
  LDI B, 1092616192
  CMPF A, B
  JLT .L127
  LD A, [FP, 5] ; exp
  ADD B, A, 1
  ST [FP, 5], B ; exp
  LD A, [FP, 0] ; f
  LDI B, 1092616192
  DIVF A, B
  ST [FP, 0], A ; f
  JMP .L126
.L127:
.L128:
  LD A, [FP, 0] ; f
  LDI B, 1065353216
  CMPF A, B
  JGE .L129
  LD A, [FP, 5] ; exp
  SUB B, A, 1
  ST [FP, 5], B ; exp
  LD A, [FP, 0] ; f
  LDI B, 1092616192
  MULF A, B
  ST [FP, 0], A ; f
  JMP .L128
.L129:
.L125:
  LD A, [FP, 0] ; f
  LD.B B, [FP, 4] ; prec
  CALL fprint
  MOV.B A, 'e'
  CALL putchar
  LD A, [FP, 5] ; exp
  CALL dprint
  MOV SP, FP
  ADD SP, 9
  POP PC, FP
printf:
  PUSH D, C, B, A
  PUSH LR, FP
  SUB SP, 13
  MOV FP, SP
  ADD A, FP, 21
  MOV B, 1
  MUL B, 4
  ADD A, B
  ST [FP, 0], A ; ap
  MOV A, 0
  ST [FP, 8], A ; n
  LD A, [FP, 21] ; format
  ST [FP, 4], A ; c
.L130:
  LD A, [FP, 4] ; c
  LD.B A, [A]
  CMP.B A, 0
  JEQ .L132
  LD A, [FP, 4] ; c
  LD.B A, [A]
  CMP.B A, '%'
  JNE .L134
  LD A, [FP, 4] ; c
  ADD B, A, 1
  ST [FP, 4], B ; c
  MOV A, 0
  ST.B [FP, 12], A ; precision
  MOV.B A, '0'
  LD B, [FP, 4] ; c
  LD.B B, [B]
  CMP.B A, B
  JGT .L135
  LD A, [FP, 4] ; c
  LD.B A, [A]
  CMP.B A, '9'
  JGT .L135
  LD A, [FP, 4] ; c
  ADD B, A, 1
  ST [FP, 4], B ; c
  LD.B A, [A]
  SUB.B A, '0'
  ST.B [FP, 12], A ; precision
.L135:
  LD A, [FP, 4] ; c
  LD.B A, [A]
  CMP.B A, 'u'
  JEQ .L138
  CMP.B A, 'd'
  JEQ .L139
  CMP.B A, 'i'
  JEQ .L140
  CMP.B A, 'x'
  JEQ .L141
  CMP.B A, 'X'
  JEQ .L142
  CMP.B A, 'f'
  JEQ .L143
  CMP.B A, 'e'
  JEQ .L144
  CMP.B A, 's'
  JEQ .L145
  CMP.B A, 'c'
  JEQ .L146
  CMP.B A, 'o'
  JEQ .L147
  CMP.B A, 'n'
  JEQ .L148
  JMP .L149
.L138:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD A, [A]
  CALL uprint
  JMP .L137
.L139:
.L140:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD A, [A]
  CALL dprint
  JMP .L137
.L141:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD A, [A]
  MOV.B B, 'a'
  CALL xprint
  JMP .L137
.L142:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD A, [A]
  MOV.B B, 'A'
  CALL xprint
  JMP .L137
.L143:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD A, [A]
  LD.B B, [FP, 12] ; precision
  CALL fprint
  JMP .L137
.L144:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD A, [A]
  LD.B B, [FP, 12] ; precision
  CALL eprint
  JMP .L137
.L145:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD A, [A]
  CALL printf
  JMP .L137
.L146:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD.B A, [A]
  CALL putchar
  JMP .L137
.L147:
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD A, [A]
  CALL oprint
  JMP .L137
.L148:
  LD A, [FP, 8] ; n
  LD A, [FP, 0] ; ap
  ADD B, A, 4
  ST [FP, 0], B ; ap
  LD B, [B]
  ST [B], A
  JMP .L137
.L149:
  LD A, [FP, 4] ; c
  LD.B A, [A]
  CALL putchar
.L137:
  JMP .L133
.L134:
  LD A, [FP, 4] ; c
  LD.B A, [A]
  CALL putchar
.L133:
.L131:
  LD A, [FP, 4] ; c
  ADD B, A, 1
  ST [FP, 4], B ; c
  LD A, [FP, 8] ; n
  ADD B, A, 1
  ST [FP, 8], B ; n
  JMP .L130
.L132:
  MOV A, 0
  ST [FP, 0], A ; ap
  MOV SP, FP
  ADD SP, 13
  POP LR, FP
  ADD SP, 16
  RET
fizzbuzz:
  PUSH LR, FP
  SUB SP, 17
  MOV FP, SP
  ST [FP, 0], A
  MOV A, 1
  ST [FP, 4], A ; n
.L150:
  LD A, [FP, 4] ; n
  LD B, [FP, 0] ; m
  CMP A, B
  JGT .L152
  MOV.B A, '\0'
  ADD B, FP, 8
  ADD B, 0
  ST.B [B], A
  LD A, [FP, 4] ; n
  MOD A, 3
  CMP A, 0
  JNE .L153
  ADD A, FP, 8
  LDI B, =.S0
  CALL strcat
.L153:
  LD A, [FP, 4] ; n
  MOD A, 5
  CMP A, 0
  JNE .L154
  ADD A, FP, 8
  LDI B, =.S1
  CALL strcat
.L154:
  ADD A, FP, 8
  CALL strlen
  CMP A, 0
  JEQ .L156
  LDI A, =.S2
  ADD B, FP, 8
  CALL printf
  JMP .L155
.L156:
  LDI A, =.S3
  LD B, [FP, 4] ; n
  CALL printf
.L155:
.L151:
  LD A, [FP, 4] ; n
  ADD B, A, 1
  ST [FP, 4], B ; n
  JMP .L150
.L152:
  MOV SP, FP
  ADD SP, 17
  POP PC, FP
main:
  PUSH LR, FP
  MOV FP, SP
  MOV A, 15
  CALL fizzbuzz
.L157:
  MOV SP, FP
  POP PC, FP