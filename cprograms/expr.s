next_rand: .word 0
heapindex: .word 0
errno: .word 0
.S0: "a\0"
.S1: "b\0"
.S2: "c\0"
.S3: "foo\0"
env:
  .word .S0
  .word 3
  .word .S1
  .word 4
  .word .S2
  .word 7
  .word .S3
  .word 10
.S4: "Invalid token %c\n\0"
.S5: "(NUM %s)\n\0"
.S6: "(VAR \"%s\")\n\0"
.S7: "(SYM '%c')\n\0"
.S8: "Cannot find name %s\n\0"
.S9: "%d \0"
.S10: "%s \0"
.S11: "%c \0"
current: .space 4
.S12: "Expected %c\n\0"
.S13: "Expected NUM, VAR, or (\n\0"
.S14: "Expected END\n\0"
.S15: "%d\n\0"
.S16: "3+3\0"
.S17: "quit\n\0"
strlen:
  PUSH B, FP
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
  JEQ .L12
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
.L12:
  LD D, [FP, 4] ; p
  JMP .L11
.L11:
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
.L14:
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
  JEQ .L15
  JMP .L14
.L15:
  LD B, [FP, 0] ; s
  JMP .L13
.L13:
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
.L17:
  LD B, [FP, 4] ; front
  LD C, [FP, 8] ; back
  CMP B, C
  JCS .L19
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
.L18:
  LD B, [FP, 4] ; front
  ADD C, B, 1
  ST [FP, 4], C ; front
  LD B, [FP, 8] ; back
  SUB C, B, 1
  ST [FP, 8], C ; back
  JMP .L17
.L19:
  LD B, [FP, 0] ; s
  JMP .L16
.L16:
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
  JMP .L51
.L51:
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
.L55:
  LD C, [FP, 16] ; low
  LD D, [FP, 24] ; high
  CMP C, D
  JGT .L56
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
  JGE .L58
  LD C, [FP, 20] ; mid
  SUB C, 1
  ST [FP, 24], C ; high
  JMP .L57
.L58:
  LD C, [FP, 28] ; cond
  CMP C, 0
  JLE .L59
  LD C, [FP, 20] ; mid
  ADD C, 1
  ST [FP, 16], C ; low
  JMP .L57
.L59:
  LD C, [FP, 20] ; mid
  LD D, [FP, 8] ; size
  MUL C, D
  JMP .L54
.L57:
  JMP .L55
.L56:
  MVN C, 1
  JMP .L54
.L54:
  MOV A, C
  MOV SP, FP
  ADD SP, 32
  POP PC, F, FP
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
  JLT .L67
  JMP .L66
.L67:
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
.L68:
  LD E, [FP, 16] ; i
  LD F, [FP, 12] ; right
  CMP E, F
  JGT .L70
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
  JGE .L71
  LD E, [FP, 0] ; v
  LD F, [FP, 4] ; size
  LD A, [FP, 20] ; last
  ADD G, 1
  ST [FP, 20], A ; last
  LD H, [FP, 16] ; i
  MOV A, E
  MOV B, F
  MOV C, G
  MOV D, H
  CALL swap
.L71:
.L69:
  LD E, [FP, 16] ; i
  ADD F, E, 1
  ST [FP, 16], F ; i
  JMP .L68
.L70:
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
.L66:
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
  JMP .L72
.L72:
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
  JNE .L79
  MVN A, 1
  JMP .L78
.L79:
  MOV A, 1
.L78:
  ST [FP, 16], A ; sign
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
  PUSH LR, C, D, FP
  SUB SP, 12
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD B, [FP, 4] ; size
  MOV A, B
  CALL malloc
  MOV B, A
  ST [FP, 8], B ; d
  LD B, [FP, 8] ; d
  LD C, [FP, 0] ; p
  LD D, [FP, 4] ; size
  MOV A, B
  MOV B, C
  MOV C, D
  CALL memcpy
  LD B, [FP, 0] ; p
  MOV A, B
  CALL free
  LD B, [FP, 8] ; d
  JMP .L90
.L90:
  MOV A, B
  MOV SP, FP
  ADD SP, 12
  POP PC, C, D, FP
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
.L92:
  LD B, [FP, 20] ; i
  LD C, [FP, 12] ; words
  CMP B, C
  JCS .L94
  MOV B, 0
  LD C, [FP, 24] ; p
  LD D, [FP, 20] ; i
  ADD C, D
  ST [C], B
.L93:
  LD B, [FP, 20] ; i
  ADD C, B, 1
  ST [FP, 20], C ; i
  JMP .L92
.L94:
  MOV B, 0
  ST [FP, 28], B ; c
.L95:
  LD B, [FP, 28] ; c
  LD C, [FP, 16] ; tail
  CMP B, C
  JCS .L97
  MOV B, 0
  LD C, [FP, 24] ; p
  LD D, [FP, 20] ; i
  ADD C, D
  LD D, [FP, 28] ; c
  ADD C, D
  ST.B [C], B
.L96:
  LD B, [FP, 28] ; c
  ADD C, B, 1
  ST [FP, 28], C ; c
  JMP .L95
.L97:
  LD B, [FP, 24] ; p
  JMP .L91
.L91:
  MOV A, B
  MOV SP, FP
  ADD SP, 32
  POP PC, C, D, FP
isupper:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  MOV.B A, 'A'
  LD.B B, [FP, 0] ; c
  CMP.B A, B
  JGT .L99
  LD.B A, [FP, 0] ; c
  CMP.B A, 'Z'
  JGT .L99
  MOV A, 1
  JMP .L100
.L99:
  MOV A, 0
.L100:
  JMP .L98
.L98:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
islower:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  MOV.B A, 'a'
  LD.B B, [FP, 0] ; c
  CMP.B A, B
  JGT .L102
  LD.B A, [FP, 0] ; c
  CMP.B A, 'z'
  JGT .L102
  MOV A, 1
  JMP .L103
.L102:
  MOV A, 0
.L103:
  JMP .L101
.L101:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
isalpha:
  PUSH LR, B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL islower
  MOV B, A
  CMP B, 0
  JNE .L105
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL isupper
  MOV B, A
  CMP B, 0
  JEQ .L106
.L105:
  MOV B, 1
  JMP .L107
.L106:
  MOV B, 0
.L107:
  JMP .L104
.L104:
  MOV A, B
  MOV SP, FP
  ADD SP, 1
  POP PC, B, FP
iscntrl:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  MOV A, 0
  LD.B B, [FP, 0] ; c
  CMP A, B
  JGT .L109
  LD.B A, [FP, 0] ; c
  CMP A, 32
  JGE .L109
  MOV A, 1
  JMP .L110
.L109:
  MOV A, 0
.L110:
  JMP .L108
.L108:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
isdigit:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  MOV.B A, '0'
  LD.B B, [FP, 0] ; c
  CMP.B A, B
  JGT .L112
  LD.B A, [FP, 0] ; c
  CMP.B A, '9'
  JGT .L112
  MOV A, 1
  JMP .L113
.L112:
  MOV A, 0
.L113:
  JMP .L111
.L111:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
isalnum:
  PUSH LR, B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL isalpha
  MOV B, A
  CMP B, 0
  JNE .L115
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL isdigit
  MOV B, A
  CMP B, 0
  JEQ .L116
.L115:
  MOV B, 1
  JMP .L117
.L116:
  MOV B, 0
.L117:
  JMP .L114
.L114:
  MOV A, B
  MOV SP, FP
  ADD SP, 1
  POP PC, B, FP
isspace:
  PUSH FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B A, [FP, 0] ; c
  CMP.B A, ' '
  JEQ .L119
  LD.B A, [FP, 0] ; c
  CMP.B A, '\t'
  JEQ .L119
  LD.B A, [FP, 0] ; c
  CMP.B A, '\n'
  JNE .L120
.L119:
  MOV A, 1
  JMP .L121
.L120:
  MOV A, 0
.L121:
  JMP .L118
.L118:
  MOV SP, FP
  ADD SP, 1
  POP FP
  RET
isxdigit:
  PUSH LR, B, C, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL isdigit
  MOV B, A
  CMP B, 0
  JNE .L123
  MOV.B B, 'A'
  LD.B C, [FP, 0] ; c
  CMP.B B, C
  JGT .L126
  LD.B B, [FP, 0] ; c
  CMP.B B, 'F'
  JLE .L123
.L126:
  MOV.B B, 'a'
  LD.B C, [FP, 0] ; c
  CMP.B B, C
  JGT .L124
  LD.B B, [FP, 0] ; c
  CMP.B B, 'f'
  JGT .L124
.L123:
  MOV B, 1
  JMP .L125
.L124:
  MOV B, 0
.L125:
  JMP .L122
.L122:
  MOV A, B
  MOV SP, FP
  ADD SP, 1
  POP PC, B, C, FP
tolower:
  PUSH LR, B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL isupper
  MOV B, A
  CMP B, 0
  JEQ .L128
  LD.B B, [FP, 0] ; c
  ADD.B B, 'a'
  SUB.B B, 'A'
  JMP .L127
.L128:
  LD.B B, [FP, 0] ; c
  JMP .L127
.L127:
  MOV A, B
  MOV SP, FP
  ADD SP, 1
  POP PC, B, FP
toupper:
  PUSH LR, B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL islower
  MOV B, A
  CMP B, 0
  JEQ .L130
  LD.B B, [FP, 0] ; c
  SUB.B B, 'a'
  SUB.B B, 'A'
  JMP .L129
.L130:
  LD.B B, [FP, 0] ; c
  JMP .L129
.L129:
  MOV A, B
  MOV SP, FP
  ADD SP, 1
  POP PC, B, FP
isgraph:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  MOV.B A, ' '
  LD.B B, [FP, 0] ; c
  CMP.B A, B
  JGE .L132
  LD.B A, [FP, 0] ; c
  CMP A, 127
  JGE .L132
  MOV A, 1
  JMP .L133
.L132:
  MOV A, 0
.L133:
  JMP .L131
.L131:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
isprint:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  MOV.B A, ' '
  LD.B B, [FP, 0] ; c
  CMP.B A, B
  JGT .L135
  LD.B A, [FP, 0] ; c
  CMP A, 127
  JGE .L135
  MOV A, 1
  JMP .L136
.L135:
  MOV A, 0
.L136:
  JMP .L134
.L134:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
ispunct:
  PUSH LR, B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL isgraph
  MOV B, A
  CMP B, 0
  JEQ .L138
  LD.B B, [FP, 0] ; c
  MOV.B A, B
  CALL isalnum
  MOV B, A
  CMP B, 0
  JNE .L138
  MOV B, 1
  JMP .L139
.L138:
  MOV B, 0
.L139:
  JMP .L137
.L137:
  MOV A, B
  MOV SP, FP
  ADD SP, 1
  POP PC, B, FP
fgetc:
  PUSH B, FP
  SUB SP, 5
  MOV FP, SP
  ST [FP, 0], A
.L141:
  LD A, [FP, 0] ; stream
  LD A, [A, 4] ; read
  LD B, [FP, 0] ; stream
  LD B, [B, 8] ; write
  CMP A, B
  JNE .L142
  JMP .L141
.L142:
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
  JMP .L140
.L140:
  MOV SP, FP
  ADD SP, 5
  POP B, FP
  RET
getchar:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
.L144:
  LDI A, =stdin
  LD A, [A]
  LD A, [A, 4] ; read
  LDI B, =stdin
  LD B, [B]
  LD B, [B, 8] ; write
  CMP A, B
  JNE .L145
  JMP .L144
.L145:
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
  JMP .L143
.L143:
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
.L147:
  LD A, [FP, 4] ; n
  SUB B, 1
  ST [FP, 4], A ; n
  CMP B, 0
  JLS .L148
  LD B, [FP, 8] ; stream
  MOV A, B
  CALL fgetc
  MOV B, A
  ST.B [FP, 12], B ; c
  CMP.B B, 0
  JEQ .L148
  LD.B B, [FP, 12] ; c
  LD C, [FP, 13] ; cs
  ADD D, C, 1
  ST [FP, 13], D ; cs
  ST.B [C], B
  JMP .L147
.L148:
  MOV.B B, '\0'
  LD C, [FP, 13] ; cs
  ST.B [C], B
  LD B, [FP, 0] ; s
  JMP .L146
.L146:
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
  LD F, [F]
  MOV A, D
  MOV B, E
  MOV C, F
  CALL fgets
  MOV D, A
  JMP .L149
.L149:
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
  JMP .L150
.L150:
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
  LD B, [B]
  LD B, [B, 0] ; buffer
  LDI C, =stdout
  LD C, [C]
  LD C, [C, 8] ; write
  ADD B, C
  ST.B [B], A
  MOV A, 0
  JMP .L151
.L151:
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
.L153:
  LD C, [FP, 0] ; s
  LD.B C, [C]
  CMP.B C, '\0'
  JEQ .L154
  LD C, [FP, 0] ; s
  LD.B C, [C]
  LD D, [FP, 4] ; stream
  MOV.B A, C
  MOV B, D
  CALL fputc
  LD C, [FP, 0] ; s
  ADD D, C, 1
  ST [FP, 0], D ; s
  JMP .L153
.L154:
  MOV C, 0
  JMP .L152
.L152:
  MOV A, C
  MOV SP, FP
  ADD SP, 8
  POP PC, C, D, FP
puts:
  PUSH LR, B, C, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; s
  LDI C, =stdout
  LD C, [C]
  MOV A, B
  MOV B, C
  CALL fputs
  MOV.B B, '\n'
  MOV.B A, B
  CALL putchar
  MOV B, 0
  JMP .L155
.L155:
  MOV A, B
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, FP
uprint:
  PUSH LR, B, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; n
  DIV B, 10
  CMP B, 0
  JEQ .L156
  LD B, [FP, 0] ; n
  DIV B, 10
  MOV A, B
  CALL uprint
.L156:
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
  JEQ .L157
  LD B, [FP, 0] ; n
  DIV B, 8
  MOV A, B
  CALL oprint
.L157:
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
  JGE .L158
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; n
  NEG B
  ST [FP, 0], B ; n
.L158:
  LD B, [FP, 0] ; n
  MOV A, B
  CALL uprint
  MOV SP, FP
  ADD SP, 4
  POP PC, B, FP
xprint:
  PUSH LR, C, FP
  SUB SP, 5
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD B, [FP, 0] ; n
  DIV B, 16
  CMP B, 0
  JEQ .L159
  LD B, [FP, 0] ; n
  DIV B, 16
  LD.B C, [FP, 4] ; uplo
  MOV A, B
  MOV.B B, C
  CALL xprint
.L159:
  LD B, [FP, 0] ; n
  MOD B, 16
  CMP B, 9
  JLS .L161
  LD B, [FP, 0] ; n
  MOD B, 16
  SUB B, 10
  LD.B C, [FP, 4] ; uplo
  ADD B, C
  MOV A, B
  CALL putchar
  JMP .L160
.L161:
  LD B, [FP, 0] ; n
  MOD B, 16
  ADD B, '0'
  MOV A, B
  CALL putchar
.L160:
  MOV SP, FP
  ADD SP, 5
  POP PC, C, FP
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
  JGE .L162
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; f
  NEGF B
  ST [FP, 0], B ; f
.L162:
  LD B, [FP, 0] ; f
  FTI B, B
  ST [FP, 5], B ; left
  LD B, [FP, 5] ; left
  MOV A, B
  CALL uprint
  LD.B B, [FP, 4] ; prec
  CMP B, 0
  JLE .L163
  MOV.B B, '.'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; f
  LD C, [FP, 5] ; left
  ITF C, C
  SUBF B, C
  ST [FP, 9], B ; right
.L164:
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
  LD.B A, [FP, 4] ; prec
  SUB.B B, 1
  ST.B [FP, 4], A ; prec
  CMP B, 0
  JGT .L164
.L165:
.L163:
  MOV SP, FP
  ADD SP, 13
  POP PC, C, FP
eprint:
  PUSH LR, C, FP
  SUB SP, 9
  MOV FP, SP
  ST [FP, 0], A
  ST.B [FP, 4], B
  LD B, [FP, 0] ; f
  MOV C, 0
  ITF C, C
  CMPF B, C
  JGE .L166
  MOV.B B, '-'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 0] ; f
  NEGF B
  ST [FP, 0], B ; f
.L166:
  MOV B, 0
  ST [FP, 5], B ; exp
  LD B, [FP, 0] ; f
  CMPF B, 0
  JEQ .L167
.L168:
  LD B, [FP, 0] ; f
  LDI C, 1092616192
  CMPF B, C
  JLT .L169
  LD B, [FP, 5] ; exp
  ADD C, B, 1
  ST [FP, 5], C ; exp
  LD B, [FP, 0] ; f
  LDI C, 1092616192
  DIVF B, C
  ST [FP, 0], B ; f
  JMP .L168
.L169:
.L170:
  LD B, [FP, 0] ; f
  LDI C, 1065353216
  CMPF B, C
  JGE .L171
  LD B, [FP, 5] ; exp
  SUB C, B, 1
  ST [FP, 5], C ; exp
  LD B, [FP, 0] ; f
  LDI C, 1092616192
  MULF B, C
  ST [FP, 0], B ; f
  JMP .L170
.L171:
.L167:
  LD B, [FP, 0] ; f
  LD.B C, [FP, 4] ; prec
  MOV A, B
  MOV.B B, C
  CALL fprint
  MOV.B B, 'e'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 5] ; exp
  MOV A, B
  CALL dprint
  MOV SP, FP
  ADD SP, 9
  POP PC, C, FP
printf:
  PUSH D, C, B, A
  PUSH LR, B, C, D, FP
  SUB SP, 13
  MOV FP, SP
  ADD B, FP, 33
  MOV C, 1
  MUL C, 4
  ADD B, C
  ST [FP, 0], B ; ap
  MOV B, 0
  ST [FP, 8], B ; n
  LD B, [FP, 33] ; format
  ST [FP, 4], B ; c
.L172:
  LD B, [FP, 4] ; c
  LD.B B, [B]
  CMP.B B, 0
  JEQ .L174
  LD B, [FP, 4] ; c
  LD.B B, [B]
  CMP.B B, '%'
  JNE .L176
  LD B, [FP, 4] ; c
  ADD C, B, 1
  ST [FP, 4], C ; c
  MOV B, 0
  ST.B [FP, 12], B ; precision
  MOV.B B, '0'
  LD C, [FP, 4] ; c
  LD.B C, [C]
  CMP.B B, C
  JGT .L177
  LD B, [FP, 4] ; c
  LD.B B, [B]
  CMP.B B, '9'
  JGT .L177
  LD B, [FP, 4] ; c
  ADD C, B, 1
  ST [FP, 4], C ; c
  LD.B B, [B]
  SUB.B B, '0'
  ST.B [FP, 12], B ; precision
.L177:
  LD B, [FP, 4] ; c
  LD.B B, [B]
  CMP.B B, 'u'
  JEQ .L180
  CMP.B B, 'd'
  JEQ .L181
  CMP.B B, 'i'
  JEQ .L182
  CMP.B B, 'x'
  JEQ .L183
  CMP.B B, 'X'
  JEQ .L184
  CMP.B B, 'f'
  JEQ .L185
  CMP.B B, 'e'
  JEQ .L186
  CMP.B B, 's'
  JEQ .L187
  CMP.B B, 'c'
  JEQ .L188
  CMP.B B, 'o'
  JEQ .L189
  CMP.B B, 'n'
  JEQ .L190
  JMP .L191
.L180:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD B, [B]
  MOV A, B
  CALL uprint
  JMP .L179
.L181:
.L182:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD B, [B]
  MOV A, B
  CALL dprint
  JMP .L179
.L183:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD B, [B]
  MOV.B C, 'a'
  MOV A, B
  MOV.B B, C
  CALL xprint
  JMP .L179
.L184:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD B, [B]
  MOV.B C, 'A'
  MOV A, B
  MOV.B B, C
  CALL xprint
  JMP .L179
.L185:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD B, [B]
  LD.B C, [FP, 12] ; precision
  MOV A, B
  MOV.B B, C
  CALL fprint
  JMP .L179
.L186:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD B, [B]
  LD.B C, [FP, 12] ; precision
  MOV A, B
  MOV.B B, C
  CALL eprint
  JMP .L179
.L187:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD B, [B]
  MOV A, B
  CALL printf
  JMP .L179
.L188:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD.B B, [B]
  MOV.B A, B
  CALL putchar
  JMP .L179
.L189:
  LD B, [FP, 0] ; ap
  ADD C, B, 4
  ST [FP, 0], C ; ap
  LD B, [B]
  MOV A, B
  CALL oprint
  JMP .L179
.L190:
  LD B, [FP, 8] ; n
  LD C, [FP, 0] ; ap
  ADD D, C, 4
  ST [FP, 0], D ; ap
  LD C, [C]
  ST [C], B
  JMP .L179
.L191:
  LD B, [FP, 4] ; c
  LD.B B, [B]
  MOV.B A, B
  CALL putchar
.L179:
  JMP .L175
.L176:
  LD B, [FP, 4] ; c
  LD.B B, [B]
  MOV.B A, B
  CALL putchar
.L175:
.L173:
  LD B, [FP, 4] ; c
  ADD C, B, 1
  ST [FP, 4], C ; c
  LD B, [FP, 8] ; n
  ADD C, B, 1
  ST [FP, 8], C ; n
  JMP .L172
.L174:
  MOV B, 0
  ST [FP, 0], B ; ap
  MOV SP, FP
  ADD SP, 13
  POP LR, B, C, D, FP
  ADD SP, 16
  RET
get:
  PUSH LR, B, C, D, E, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  MOV C, 0
  ST [FP, 4], C ; i
.L193:
  LD C, [FP, 4] ; i
  CMP C, 4
  JCS .L195
  LD C, [FP, 0] ; key
  LDI D, =env
  LD E, [FP, 4] ; i
  MUL E, 8
  ADD D, E
  LD D, [D, 0] ; key
  MOV A, C
  MOV B, D
  CALL strcmp
  MOV C, A
  CMP C, 0
  JNE .L196
  LDI C, =env
  LD D, [FP, 4] ; i
  MUL D, 8
  ADD C, D
  JMP .L192
.L196:
.L194:
  LD C, [FP, 4] ; i
  ADD D, C, 1
  ST [FP, 4], D ; i
  JMP .L193
.L195:
  MOV C, 0
  JMP .L192
.L192:
  MOV A, C
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, D, E, FP
freeTokens:
  PUSH LR, B, C, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
.L197:
  LD B, [FP, 0] ; head
  MOV C, 0
  CMP B, C
  JEQ .L198
  LD B, [FP, 0] ; head
  LD.B B, [B, 0] ; type
  CMP.B B, 0
  JEQ .L201
  CMP.B B, 1
  JEQ .L202
  JMP .L200
.L201:
.L202:
  LD B, [FP, 0] ; head
  LD B, [B, 1] ; lexeme
  MOV A, B
  CALL free
.L200:
  LD B, [FP, 0] ; head
  ST [FP, 4], B ; temp
  LD B, [FP, 0] ; head
  LD B, [B, 7] ; next
  ST [FP, 0], B ; head
  LD B, [FP, 4] ; temp
  MOV A, B
  CALL free
  JMP .L197
.L198:
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, FP
consume:
  PUSH LR, E, FP
  SUB SP, 34
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST.B [FP, 8], C
  ST [FP, 9], D
  MOV B, 0
  ST [FP, 13], B ; i
  MOV B, 0
  ST.B [FP, 33], B ; lexeme_len
.L204:
  LD B, [FP, 4] ; input
  LD C, [FP, 13] ; i
  ADD D, C, 1
  ST [FP, 13], D ; i
  ADD B, C
  LD.B B, [B]
  ADD C, FP, 17
  LD.B D, [FP, 33] ; lexeme_len
  ADD.B E, D, 1
  ST.B [FP, 33], E ; lexeme_len
  ADD C, D
  ST.B [C], B
  LD B, [FP, 4] ; input
  LD C, [FP, 13] ; i
  ADD B, C
  LD.B B, [B]
  MOV.B A, B
  LD B, [FP, 9] ; test
  CALL B
  MOV B, A
  CMP B, 0
  JEQ .L206
  LD.B B, [FP, 33] ; lexeme_len
  CMP B, 16
  JLT .L204
.L206:
.L205:
  MOV.B B, '\0'
  ADD C, FP, 17
  LD.B D, [FP, 33] ; lexeme_len
  ADD C, D
  ST.B [C], B
  ADD B, FP, 17
  MOV A, B
  CALL strdup
  MOV B, A
  LD C, [FP, 0] ; new
  ST [C, 1], B ; lexeme
  LD.B B, [FP, 8] ; type
  LD C, [FP, 0] ; new
  ST.B [C, 0], B ; type
  LD B, [FP, 13] ; i
  JMP .L203
.L203:
  MOV A, B
  MOV SP, FP
  ADD SP, 34
  POP PC, E, FP
lex:
  PUSH LR, B, C, D, E, F, FP
  SUB SP, 26
  MOV FP, SP
  ST [FP, 0], A
  MOV B, 0
  ST [FP, 4], B ; i
  LD B, [FP, 0] ; input
  MOV A, B
  CALL strlen
  MOV B, A
  ST [FP, 8], B ; len
  MOV B, 0
  ST [FP, 12], B ; head
  MOV B, 0
  ST [FP, 16], B ; tail
  MOV B, 1
  ST.H [FP, 20], B ; line
.L208:
  LD B, [FP, 4] ; i
  LD C, [FP, 8] ; len
  CMP B, C
  JCS .L209
  LD B, [FP, 0] ; input
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B B, [B]
  MOV.B A, B
  CALL isspace
  MOV B, A
  CMP B, 0
  JEQ .L211
  LD B, [FP, 0] ; input
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B B, '\n'
  JNE .L212
  LD.H B, [FP, 20] ; line
  ADD.H C, B, 1
  ST.H [FP, 20], C ; line
.L212:
  LD B, [FP, 4] ; i
  ADD C, B, 1
  ST [FP, 4], C ; i
  JMP .L210
.L211:
  MOV B, 11
  MOV A, B
  CALL malloc
  MOV B, A
  ST [FP, 22], B ; new
  LD B, [FP, 0] ; input
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B B, [B]
  MOV.B A, B
  CALL isdigit
  MOV B, A
  CMP B, 0
  JEQ .L214
  LD B, [FP, 4] ; i
  LD C, [FP, 22] ; new
  LD D, [FP, 0] ; input
  LD E, [FP, 4] ; i
  ADD D, E
  MOV E, 0
  LDI F, =isdigit
  MOV A, C
  MOV B, D
  MOV C, E
  MOV D, F
  CALL consume
  MOV C, A
  ADD B, C
  ST [FP, 4], B ; i
  JMP .L213
.L214:
  LD B, [FP, 0] ; input
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B B, [B]
  MOV.B A, B
  CALL isalpha
  MOV B, A
  CMP B, 0
  JEQ .L215
  LD B, [FP, 4] ; i
  LD C, [FP, 22] ; new
  LD D, [FP, 0] ; input
  LD E, [FP, 4] ; i
  ADD D, E
  MOV E, 1
  LDI F, =isalpha
  MOV A, C
  MOV B, D
  MOV C, E
  MOV D, F
  CALL consume
  MOV C, A
  ADD B, C
  ST [FP, 4], B ; i
  JMP .L213
.L215:
  LD B, [FP, 0] ; input
  LD C, [FP, 4] ; i
  ADD B, C
  LD.B B, [B]
  CMP.B B, '('
  JEQ .L218
  CMP.B B, ')'
  JEQ .L219
  CMP.B B, '+'
  JEQ .L220
  CMP.B B, '-'
  JEQ .L221
  CMP.B B, '*'
  JEQ .L222
  CMP.B B, '/'
  JEQ .L223
  JMP .L224
.L218:
.L219:
.L220:
.L221:
.L222:
.L223:
  MOV B, 2
  LD C, [FP, 22] ; new
  ST.B [C, 0], B ; type
  LD B, [FP, 0] ; input
  LD C, [FP, 4] ; i
  ADD D, C, 1
  ST [FP, 4], D ; i
  ADD B, C
  LD.B B, [B]
  LD C, [FP, 22] ; new
  ST.B [C, 1], B ; sym
  JMP .L217
.L224:
  MOV B, 3
  LD C, [FP, 22] ; new
  ST.B [C, 0], B ; type
  LD B, [FP, 0] ; input
  LD C, [FP, 4] ; i
  ADD D, C, 1
  ST [FP, 4], D ; i
  ADD B, C
  LD.B B, [B]
  LD C, [FP, 22] ; new
  ST.B [C, 1], B ; sym
  LDI B, =.S4
  LD C, [FP, 22] ; new
  LD.B C, [C, 1] ; sym
  MOV A, B
  MOV.B B, C
  CALL printf
  MOV B, 200
  LDI C, =errno
  ST [C], B
.L217:
.L213:
  LD.H B, [FP, 20] ; line
  LD C, [FP, 22] ; new
  ST.H [C, 5], B ; line
  LD B, [FP, 12] ; head
  MOV C, 0
  CMP B, C
  JNE .L226
  LD B, [FP, 22] ; new
  ST [FP, 16], B ; tail
  ST [FP, 12], B ; head
  JMP .L225
.L226:
  LD B, [FP, 22] ; new
  LD C, [FP, 16] ; tail
  ST [C, 7], B ; next
  LD B, [FP, 22] ; new
  ST [FP, 16], B ; tail
.L225:
.L210:
  JMP .L208
.L209:
  MOV B, 11
  MOV A, B
  CALL malloc
  MOV B, A
  ST [FP, 22], B ; end
  MOV B, 4
  LD C, [FP, 22] ; end
  ST.B [C, 0], B ; type
  MOV.B B, '\0'
  LD C, [FP, 22] ; end
  ST.B [C, 1], B ; sym
  LD.H B, [FP, 20] ; line
  LD C, [FP, 22] ; end
  ST.H [C, 5], B ; line
  MOV B, 0
  LD C, [FP, 22] ; end
  ST [C, 7], B ; next
  LD B, [FP, 22] ; end
  LD C, [FP, 16] ; tail
  ST [C, 7], B ; next
  LD B, [FP, 12] ; head
  JMP .L207
.L207:
  MOV A, B
  MOV SP, FP
  ADD SP, 26
  POP PC, B, C, D, E, F, FP
printTokens:
  PUSH LR, B, C, D, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
.L227:
  LD C, [FP, 0] ; head
  MOV D, 0
  CMP C, D
  JEQ .L229
  LD C, [FP, 0] ; head
  LD.B C, [C, 0] ; type
  CMP.B C, 0
  JEQ .L232
  CMP.B C, 1
  JEQ .L233
  CMP.B C, 2
  JEQ .L234
  JMP .L231
.L232:
  LDI C, =.S5
  LD D, [FP, 0] ; head
  LD D, [D, 1] ; lexeme
  MOV A, C
  MOV B, D
  CALL printf
  JMP .L231
.L233:
  LDI C, =.S6
  LD D, [FP, 0] ; head
  LD D, [D, 1] ; lexeme
  MOV A, C
  MOV B, D
  CALL printf
  JMP .L231
.L234:
  LDI C, =.S7
  LD D, [FP, 0] ; head
  LD.B D, [D, 1] ; sym
  MOV A, C
  MOV.B B, D
  CALL printf
.L231:
.L228:
  LD C, [FP, 0] ; head
  LD C, [C, 7] ; next
  ST [FP, 0], C ; head
  JMP .L227
.L229:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, D, FP
allocNum:
  PUSH LR, B, C, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  MOV B, 9
  MOV A, B
  CALL malloc
  MOV B, A
  ST [FP, 4], B ; node
  MOV B, 0
  LD C, [FP, 4] ; node
  ST.B [C, 0], B ; type
  LD B, [FP, 0] ; token
  LD C, [FP, 4] ; node
  ST [C, 1], B ; token
  LD B, [FP, 0] ; token
  LD B, [B, 1] ; lexeme
  MOV A, B
  CALL atoi
  MOV B, A
  LD C, [FP, 4] ; node
  ST [C, 5], B ; num
  LD B, [FP, 4] ; node
  JMP .L235
.L235:
  MOV A, B
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, FP
allocVar:
  PUSH LR, B, C, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  MOV B, 9
  MOV A, B
  CALL malloc
  MOV B, A
  ST [FP, 4], B ; node
  MOV B, 1
  LD C, [FP, 4] ; node
  ST.B [C, 0], B ; type
  LD B, [FP, 0] ; token
  LD C, [FP, 4] ; node
  ST [C, 1], B ; token
  LD B, [FP, 0] ; token
  LD B, [B, 1] ; lexeme
  LD C, [FP, 4] ; node
  ST [C, 5], B ; var
  LD B, [FP, 4] ; node
  JMP .L236
.L236:
  MOV A, B
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, FP
add_:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; l
  LD B, [FP, 4] ; r
  ADD A, B
  JMP .L237
.L237:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
sub_:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; l
  LD B, [FP, 4] ; r
  SUB A, B
  JMP .L238
.L238:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
mul_:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; l
  LD B, [FP, 4] ; r
  MUL A, B
  JMP .L239
.L239:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
div_:
  PUSH FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  LD A, [FP, 0] ; l
  LD B, [FP, 4] ; r
  DIV A, B
  JMP .L240
.L240:
  MOV SP, FP
  ADD SP, 8
  POP FP
  RET
allocBinary:
  PUSH LR, FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  ST [FP, 4], B
  ST [FP, 8], C
  MOV B, 9
  MOV A, B
  CALL malloc
  MOV B, A
  ST [FP, 12], B ; node
  MOV B, 2
  LD C, [FP, 12] ; node
  ST.B [C, 0], B ; type
  LD B, [FP, 0] ; token
  LD C, [FP, 12] ; node
  ST [C, 1], B ; token
  MOV B, 12
  MOV A, B
  CALL malloc
  MOV B, A
  LD C, [FP, 12] ; node
  ST [C, 5], B ; binary
  LD B, [FP, 12] ; node
  LD B, [B, 1] ; token
  LD.B B, [B, 1] ; sym
  CMP.B B, '+'
  JEQ .L244
  CMP.B B, '-'
  JEQ .L245
  CMP.B B, '*'
  JEQ .L246
  CMP.B B, '/'
  JEQ .L247
  JMP .L243
.L244:
  LDI B, =add_
  LD C, [FP, 12] ; node
  LD C, [C, 5] ; binary
  ST [C, 0], B ; op
  JMP .L243
.L245:
  LDI B, =sub_
  LD C, [FP, 12] ; node
  LD C, [C, 5] ; binary
  ST [C, 0], B ; op
  JMP .L243
.L246:
  LDI B, =mul_
  LD C, [FP, 12] ; node
  LD C, [C, 5] ; binary
  ST [C, 0], B ; op
  JMP .L243
.L247:
  LDI B, =div_
  LD C, [FP, 12] ; node
  LD C, [C, 5] ; binary
  ST [C, 0], B ; op
.L243:
  LD B, [FP, 4] ; left
  LD C, [FP, 12] ; node
  LD C, [C, 5] ; binary
  ST [C, 4], B ; left
  LD B, [FP, 8] ; right
  LD C, [FP, 12] ; node
  LD C, [C, 5] ; binary
  ST [C, 8], B ; right
  LD B, [FP, 12] ; node
  JMP .L241
.L241:
  MOV A, B
  MOV SP, FP
  ADD SP, 16
  POP PC, FP
freeNode:
  PUSH LR, B, C, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; node
  MOV C, 0
  CMP B, C
  JEQ .L248
  LD B, [FP, 0] ; node
  LD.B B, [B, 0] ; type
  CMP B, 2
  JNE .L249
  LD B, [FP, 0] ; node
  LD B, [B, 5] ; binary
  LD B, [B, 4] ; left
  MOV A, B
  CALL freeNode
  LD B, [FP, 0] ; node
  LD B, [B, 5] ; binary
  LD B, [B, 8] ; right
  MOV A, B
  CALL freeNode
  LD B, [FP, 0] ; node
  LD B, [B, 5] ; binary
  MOV A, B
  CALL free
.L249:
  LD B, [FP, 0] ; node
  MOV A, B
  CALL free
.L248:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, FP
eval:
  PUSH LR, B, C, D, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LD C, [FP, 0] ; node
  LD.B C, [C, 0] ; type
  CMP.B C, 0
  JEQ .L253
  CMP.B C, 1
  JEQ .L254
  CMP.B C, 2
  JEQ .L255
  JMP .L252
.L253:
  LD C, [FP, 0] ; node
  LD C, [C, 5] ; num
  JMP .L250
.L254:
  LD C, [FP, 0] ; node
  LD C, [C, 5] ; var
  MOV A, C
  CALL get
  MOV C, A
  ST [FP, 4], C ; var
  LD C, [FP, 4] ; var
  MOV D, 0
  CMP C, D
  JNE .L256
  LDI C, =.S8
  LD D, [FP, 0] ; node
  LD D, [D, 5] ; var
  MOV A, C
  MOV B, D
  CALL printf
  MOV C, 201
  LDI D, =errno
  ST [D], C
  MOV C, 0
  JMP .L250
.L256:
  LD C, [FP, 4] ; var
  LD C, [C, 4] ; value
  JMP .L250
.L255:
  LD C, [FP, 0] ; node
  LD C, [C, 5] ; binary
  LD C, [C, 4] ; left
  MOV A, C
  CALL eval
  MOV C, A
  LD D, [FP, 0] ; node
  LD D, [D, 5] ; binary
  LD D, [D, 8] ; right
  MOV A, D
  CALL eval
  MOV D, A
  MOV A, C
  MOV B, D
  LD C, [FP, 0] ; node
  LD C, [C, 5] ; binary
  LD C, [C, 0] ; op
  CALL C
  MOV C, A
  JMP .L250
.L252:
.L250:
  MOV A, C
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, D, FP
printNode:
  PUSH LR, B, C, D, FP
  SUB SP, 4
  MOV FP, SP
  ST [FP, 0], A
  LD C, [FP, 0] ; node
  LD.B C, [C, 0] ; type
  CMP.B C, 0
  JEQ .L259
  CMP.B C, 1
  JEQ .L260
  CMP.B C, 2
  JEQ .L261
  JMP .L258
.L259:
  LDI C, =.S9
  LD D, [FP, 0] ; node
  LD D, [D, 5] ; num
  MOV A, C
  MOV B, D
  CALL printf
  JMP .L258
.L260:
  LDI C, =.S10
  LD D, [FP, 0] ; node
  LD D, [D, 5] ; var
  MOV A, C
  MOV B, D
  CALL printf
  JMP .L258
.L261:
  LD C, [FP, 0] ; node
  LD C, [C, 5] ; binary
  LD C, [C, 4] ; left
  MOV A, C
  CALL printNode
  LD C, [FP, 0] ; node
  LD C, [C, 5] ; binary
  LD C, [C, 8] ; right
  MOV A, C
  CALL printNode
  LDI C, =.S11
  LD D, [FP, 0] ; node
  LD D, [D, 1] ; token
  LD.B D, [D, 1] ; sym
  MOV A, C
  MOV.B B, D
  CALL printf
.L258:
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, D, FP
next:
  PUSH B, FP
  SUB SP, 4
  MOV FP, SP
  LDI A, =current
  LD A, [A]
  ST [FP, 0], A ; next
  LDI A, =current
  LD A, [A]
  LD A, [A, 7] ; next
  LDI B, =current
  ST [B], A
  LD A, [FP, 0] ; next
  JMP .L262
.L262:
  MOV SP, FP
  ADD SP, 4
  POP B, FP
  RET
peek:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LDI A, =current
  LD A, [A]
  LD.B A, [A, 0] ; type
  LD.B B, [FP, 0] ; type
  CMP.B A, B
  MOVEQ A, 1
  MOVNE A, 0
  JMP .L263
.L263:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
peek_sym:
  PUSH B, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LDI A, =current
  LD A, [A]
  LD.B A, [A, 1] ; sym
  LD.B B, [FP, 0] ; sym
  CMP.B A, B
  MOVEQ A, 1
  MOVNE A, 0
  JMP .L264
.L264:
  MOV SP, FP
  ADD SP, 1
  POP B, FP
  RET
accept:
  PUSH LR, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B A, [FP, 0] ; sym
  MOV.B A, A
  CALL peek_sym
  CMP.B A, 0
  JEQ .L266
  CALL next
  MOV A, 1
  JMP .L265
.L266:
  MOV A, 0
  JMP .L265
.L265:
  MOV SP, FP
  ADD SP, 1
  POP PC, FP
expect:
  PUSH LR, B, C, D, FP
  SUB SP, 1
  MOV FP, SP
  ST.B [FP, 0], A
  LD.B C, [FP, 0] ; sym
  MOV.B A, C
  CALL peek_sym
  MOV C, A
  CMP.B C, 0
  JEQ .L268
  CALL next
  JMP .L267
.L268:
  LDI C, =.S12
  LD.B D, [FP, 0] ; sym
  MOV A, C
  MOV.B B, D
  CALL printf
  MOV C, 202
  LDI D, =errno
  ST [D], C
.L267:
  MOV SP, FP
  ADD SP, 1
  POP PC, B, C, D, FP
factor:
  PUSH LR, B, C, FP
  SUB SP, 4
  MOV FP, SP
  MOV B, 0
  MOV A, B
  CALL peek
  MOV B, A
  CMP.B B, 0
  JEQ .L271
  CALL next
  MOV B, A
  MOV A, B
  CALL allocNum
  MOV B, A
  ST [FP, 0], B ; factor
  JMP .L270
.L271:
  MOV B, 1
  MOV A, B
  CALL peek
  MOV B, A
  CMP.B B, 0
  JEQ .L272
  CALL next
  MOV B, A
  MOV A, B
  CALL allocVar
  MOV B, A
  ST [FP, 0], B ; factor
  JMP .L270
.L272:
  MOV.B B, '('
  MOV.B A, B
  CALL accept
  MOV B, A
  CMP.B B, 0
  JEQ .L273
  CALL expr
  MOV B, A
  ST [FP, 0], B ; factor
  MOV.B B, ')'
  MOV.B A, B
  CALL expect
  JMP .L270
.L273:
  LDI B, =.S13
  MOV A, B
  CALL printf
  MOV B, 202
  LDI C, =errno
  ST [C], B
  MOV B, 0
  ST [FP, 0], B ; factor
.L270:
  LD B, [FP, 0] ; factor
  JMP .L269
.L269:
  MOV A, B
  MOV SP, FP
  ADD SP, 4
  POP PC, B, C, FP
term:
  PUSH LR, B, C, D, E, F, FP
  SUB SP, 8
  MOV FP, SP
  CALL factor
  MOV D, A
  ST [FP, 0], D ; term
.L275:
  MOV.B D, '*'
  MOV.B A, D
  CALL peek_sym
  MOV D, A
  CMP.B D, 0
  JNE .L277
  MOV.B D, '/'
  MOV.B A, D
  CALL peek_sym
  MOV D, A
  CMP.B D, 0
  JEQ .L276
.L277:
  CALL next
  MOV D, A
  ST [FP, 4], D ; token
  LD D, [FP, 4] ; token
  LD E, [FP, 0] ; term
  CALL factor
  MOV F, A
  MOV A, D
  MOV B, E
  MOV C, F
  CALL allocBinary
  MOV D, A
  ST [FP, 0], D ; term
  JMP .L275
.L276:
  LD D, [FP, 0] ; term
  JMP .L274
.L274:
  MOV A, D
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, D, E, F, FP
expr:
  PUSH LR, B, C, D, E, F, FP
  SUB SP, 8
  MOV FP, SP
  CALL term
  MOV D, A
  ST [FP, 0], D ; expr
.L279:
  MOV.B D, '+'
  MOV.B A, D
  CALL peek_sym
  MOV D, A
  CMP.B D, 0
  JNE .L281
  MOV.B D, '-'
  MOV.B A, D
  CALL peek_sym
  MOV D, A
  CMP.B D, 0
  JEQ .L280
.L281:
  CALL next
  MOV D, A
  ST [FP, 4], D ; token
  LD D, [FP, 4] ; token
  LD E, [FP, 0] ; expr
  CALL term
  MOV F, A
  MOV A, D
  MOV B, E
  MOV C, F
  CALL allocBinary
  MOV D, A
  ST [FP, 0], D ; expr
  JMP .L279
.L280:
  LD D, [FP, 0] ; expr
  JMP .L278
.L278:
  MOV A, D
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, D, E, F, FP
parse:
  PUSH LR, B, C, FP
  SUB SP, 8
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; head
  LDI C, =current
  ST [C], B
  CALL expr
  MOV B, A
  ST [FP, 4], B ; root
  LDI B, =current
  LD B, [B]
  LD.B B, [B, 0] ; type
  CMP B, 4
  JEQ .L283
  LDI B, =.S14
  MOV A, B
  CALL printf
  MOV B, 202
  LDI C, =errno
  ST [C], B
.L283:
  LD B, [FP, 4] ; root
  JMP .L282
.L282:
  MOV A, B
  MOV SP, FP
  ADD SP, 8
  POP PC, B, C, FP
exec:
  PUSH LR, B, C, FP
  SUB SP, 16
  MOV FP, SP
  ST [FP, 0], A
  LD B, [FP, 0] ; input
  MOV A, B
  CALL lex
  MOV B, A
  ST [FP, 4], B ; head
  LDI B, =errno
  LD B, [B]
  CMP B, 0
  JNE .L284
  LD B, [FP, 4] ; head
  MOV A, B
  CALL printTokens
  LD B, [FP, 4] ; head
  MOV A, B
  CALL parse
  MOV B, A
  ST [FP, 8], B ; tree
  LDI B, =errno
  LD B, [B]
  CMP B, 0
  JNE .L285
  LD B, [FP, 8] ; tree
  MOV A, B
  CALL printNode
  MOV.B B, '\n'
  MOV.B A, B
  CALL putchar
  LD B, [FP, 8] ; tree
  MOV A, B
  CALL eval
  MOV B, A
  ST [FP, 12], B ; value
  LDI B, =errno
  LD B, [B]
  CMP B, 0
  JNE .L286
  LDI B, =.S15
  LD C, [FP, 12] ; value
  MOV A, B
  MOV B, C
  CALL printf
.L286:
.L285:
  LD B, [FP, 8] ; tree
  MOV A, B
  CALL freeNode
.L284:
  LD B, [FP, 4] ; head
  MOV A, B
  CALL freeTokens
  MOV SP, FP
  ADD SP, 16
  POP PC, B, C, FP
main:
  PUSH LR, B, FP
  MOV FP, SP
  LDI B, =.S16
  MOV A, B
  CALL exec
  MOV B, 0
  JMP .L287
.L287:
  MOV A, B
  MOV SP, FP
  POP PC, B, FP
loop:
  PUSH LR, A, B, C, D, FP
  SUB SP, 44
  MOV FP, SP
  MOV.B B, '\0'
  ADD C, FP, 0
  ADD C, 0
  ST.B [C], B
.L288:
  MOV B, 1
  CMP B, 0
  JEQ .L289
  ADD B, FP, 0
  MOV C, 32
  LDI D, =stdin
  LD D, [D]
  MOV A, B
  MOV B, C
  MOV C, D
  CALL fgets
  ADD B, FP, 0
  LDI C, =.S17
  MOV A, B
  MOV B, C
  CALL strcmp
  MOV B, A
  CMP B, 0
  JNE .L290
  JMP .L289
.L290:
  ADD B, FP, 0
  MOV A, B
  CALL lex
  MOV B, A
  ST [FP, 32], B ; head
  LDI B, =errno
  LD B, [B]
  CMP B, 0
  JNE .L291
  LD B, [FP, 32] ; head
  MOV A, B
  CALL parse
  MOV B, A
  ST [FP, 36], B ; tree
  LDI B, =errno
  LD B, [B]
  CMP B, 0
  JNE .L292
  LD B, [FP, 36] ; tree
  MOV A, B
  CALL eval
  MOV B, A
  ST [FP, 40], B ; value
  LDI B, =errno
  LD B, [B]
  CMP B, 0
  JNE .L293
  LDI B, =.S15
  LD C, [FP, 40] ; value
  MOV A, B
  MOV B, C
  CALL printf
.L293:
.L292:
  LD B, [FP, 36] ; tree
  MOV A, B
  CALL freeNode
.L291:
  LD B, [FP, 32] ; head
  MOV A, B
  CALL freeTokens
  MOV B, 0
  LDI C, =errno
  ST [C], B
  JMP .L288
.L289:
  MOV SP, FP
  ADD SP, 44
  POP PC, A, B, C, D, FP