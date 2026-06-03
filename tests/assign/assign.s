jmp: .space 64
env: .word 0
n: .word 0
.S0: "%d\n\0"
.S1: "a\0"
.S2: "b\0"
.S3: "c\0"
.S4: "Testing123\0"
.S5: "a+b*c\0"
.S6: "(a+b)*c\0"
.S7: "x = a + 1\0"
.S8: "x\0"
.S9: "Welcome\0"
.S10: "quit\0"
.S11: "NUM\0"
.S12: "VAR\0"
.S13: "SYM\0"
.S14: "BAD\0"
.S15: "END\0"
TokenTypeMap:
  .word .S11
  .word .S12
  .word .S13
  .word .S14
  .word .S15
.S16: "Bad token \"%c\"\n\0"
.S17: "(NUM %s)\n\0"
.S18: "(VAR \"%s\")\n\0"
.S19: "(SYM '%c')\n\0"
.L54:
  .word .L55
  .word .L56
  .word .L59
  .word .L57
  .word .L59
  .word .L58
.L69:
  .word .L70
  .word .L71
  .word .L72
  .word .L73
.S20: "Cannot find name %s\n\0"
.S21: "%d \0"
.S22: "%s \0"
.S23: "%c \0"
current: .word 0
.S24: "Expected %s\n\0"
.S25: "Expected %c\n\0"
.S26: "Expected NUM, VAR, or (\n\0"
.S27: "Can only assign to variables\0"
next_rand: .word 0
base: .space 8
freehead: .word 0
exec:
  PUSH   B, LR
  SUB    SP, 16
  ST     [SP, 0], A ; input
  MOV    A, 0
  ST     [SP, 4], A ; head
  MOV    A, 0
  ST     [SP, 8], A ; tree
  LDI    A, =jmp
  CALL   setjmp
  CMP    A, 0
  JNE    .L0
  LD     A, [SP, 0] ; input
  CALL   lex
  ST     [SP, 4], A ; head
  CALL   printTokens
  LD     A, [SP, 4] ; head
  CALL   parse
  ST     [SP, 8], A ; tree
  CALL   printNode
  MOV.B  A, '\n'
  CALL   putchar
  LD     A, [SP, 8] ; tree
  CALL   eval
  ST     [SP, 12], A ; value
  LDI    A, =.S0
  LD     B, [SP, 12] ; value
  CALL   printf
.L0:
  LD     A, [SP, 8] ; tree
  CALL   freeNode
  MOV    A, 0
  ST     [SP, 8], A ; tree
  LD     A, [SP, 4] ; head
  CALL   freeTokens
  MOV    A, 0
  ST     [SP, 4], A ; head
  ADD    SP, 16
  POP    B, PC
main:
  PUSH   B, C, LR
  MOV    A, 16
  CALL   _allocIntMap
  LDI    B, =env
  ST     [B], A
  LDI    A, =env
  LD     A, [A]
  LDI    B, =.S1
  MOV    C, 3
  CALL   IntMap_set
  LDI    A, =env
  LD     A, [A]
  LDI    B, =.S2
  MOV    C, 4
  CALL   IntMap_set
  LDI    A, =env
  LD     A, [A]
  LDI    B, =.S3
  MOV    C, 7
  CALL   IntMap_set
  LDI    A, =.S4
  CALL   puts
  LDI    A, =.S5
  CALL   exec
  LDI    A, =.S6
  CALL   exec
  LDI    A, =.S7
  CALL   exec
  LDI    A, =.S8
  CALL   exec
  LDI    A, =.S9
  CALL   puts
  CALL   loop
  LDI    A, =env
  LD     A, [A]
  CALL   freeIntMap
  MOV    A, 0
.L1:
  POP    B, C, PC
loop:
  PUSH   A, B, C, LR
  SUB    SP, 32
.L3:
  MOV.B  A, '\0'
  ST.B   [SP, 0], A ; buf
  ADD    A, SP, 0 ; buf
  MOV    B, 32
  LDI    C, =stdin
  LD     C, [C]
  CALL   fgets
  ADD    A, SP, 0 ; buf
  LDI    B, =.S10
  CALL   strcmp
  CMP    A, 0
  JNE    .L5
  JMP    .L2
.L5:
  ADD    A, SP, 0 ; buf
  CALL   exec
  JMP    .L3
.L4:
.L2:
  ADD    SP, 32
  POP    A, B, C, PC
freeTokens:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; head
.L6:
  LD     A, [SP, 0] ; head
  CMP    A, 0
  JEQ    .L7
  LD     A, [SP, 0] ; head
  LD.B   A, [A, 0] ; .type
  CMP.B  A, 0
  JEQ    .L10
  CMP.B  A, 1
  JEQ    .L11
  JMP    .L9
.L10:
.L11:
  LD     A, [SP, 0] ; head
  LD     A, [A, 1] ; .lexeme
  CALL   free
.L9:
  LD     A, [SP, 0] ; head
  ST     [SP, 4], A ; temp
  LD     A, [SP, 0] ; head
  LD     A, [A, 7] ; .next
  ST     [SP, 0], A ; head
  LD     A, [SP, 4] ; temp
  CALL   free
  JMP    .L6
.L7:
  ADD    SP, 8
  POP    PC
consume:
  PUSH   LR
  SUB    SP, 34
  ST     [SP, 0], A ; new
  ST     [SP, 4], B ; input
  ST.B   [SP, 8], C ; type
  ST     [SP, 9], D ; test
  MOV    A, 0
  ST     [SP, 13], A ; i
  MOV    A, 0
  ST.B   [SP, 33], A ; lexeme_len
.L13:
  LD     A, [SP, 4] ; input
  LD     B, [SP, 13] ; i
  ADD    C, B, 1
  ST     [SP, 13], C ; i
  LD.B   A, [A, B]
  ADD    B, SP, 17 ; lexeme_buffer
  LD.B   C, [SP, 33] ; lexeme_len
  ADD.B  D, C, 1
  ST.B   [SP, 33], D ; lexeme_len
  ST.B   [B, C], A
  LD     A, [SP, 4] ; input
  LD     B, [SP, 13] ; i
  LD.B   A, [A, B]
  LD     B, [SP, 9] ; test
  CALL   B
  CMP    A, 0
  JEQ    .L15
  LD.B   A, [SP, 33] ; lexeme_len
  CMP    A, 15
  JLT    .L13
.L15:
.L14:
  MOV.B  A, '\0'
  ADD    B, SP, 17 ; lexeme_buffer
  LD.B   C, [SP, 33] ; lexeme_len
  ST.B   [B, C], A
  ADD    A, SP, 17 ; lexeme_buffer
  CALL   strdup
  LD     B, [SP, 0] ; new
  ST     [B, 1], A ; .lexeme
  LD.B   A, [SP, 8] ; type
  LD     B, [SP, 0] ; new
  ST.B   [B, 0], A ; .type
  LD     A, [SP, 13] ; i
.L12:
  ADD    SP, 34
  POP    PC
lex:
  PUSH   B, C, D, E, LR
  SUB    SP, 26
  ST     [SP, 0], A ; input
  MOV    A, 0
  ST     [SP, 4], A ; i
  LD     A, [SP, 0] ; input
  CALL   strlen
  ST     [SP, 8], A ; len
  MOV    A, 0
  ST     [SP, 12], A ; head
  MOV    A, 0
  ST     [SP, 16], A ; tail
  MOV    A, 1
  ST.H   [SP, 20], A ; line
.L17:
  LD     A, [SP, 4] ; i
  LD     B, [SP, 8] ; len
  CMP    A, B
  JCS    .L18
  LD     A, [SP, 0] ; input
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  CALL   isspace
  CMP    A, 0
  JEQ    .L20
  LD     A, [SP, 0] ; input
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\n'
  JNE    .L21
  LD.H   A, [SP, 20] ; line
  ADD.H  A, 1
  ST.H   [SP, 20], A ; line
.L21:
  LD     A, [SP, 4] ; i
  ADD    A, 1
  ST     [SP, 4], A ; i
  JMP    .L19
.L20:
  MOV    A, 11
  CALL   malloc
  ST     [SP, 22], A ; new
  LD     A, [SP, 0] ; input
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  CALL   isdigit
  CMP    A, 0
  JEQ    .L23
  LD     E, [SP, 4] ; i
  LD     A, [SP, 22] ; new
  LD     B, [SP, 0] ; input
  ADD    B, E
  MOV    C, 0
  LDI    D, =isdigit
  CALL   consume
  ADD    A, E, A
  ST     [SP, 4], A ; i
  JMP    .L22
.L23:
  LD     A, [SP, 0] ; input
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  CALL   isalpha
  CMP    A, 0
  JEQ    .L24
  LD     E, [SP, 4] ; i
  LD     A, [SP, 22] ; new
  LD     B, [SP, 0] ; input
  ADD    B, E
  MOV    C, 1
  LDI    D, =isalpha
  CALL   consume
  ADD    A, E, A
  ST     [SP, 4], A ; i
  JMP    .L22
.L24:
  LD     A, [SP, 0] ; input
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  CMP.B  A, '('
  JEQ    .L27
  CMP.B  A, ')'
  JEQ    .L28
  CMP.B  A, '+'
  JEQ    .L29
  CMP.B  A, '-'
  JEQ    .L30
  CMP.B  A, '*'
  JEQ    .L31
  CMP.B  A, '/'
  JEQ    .L32
  CMP.B  A, '='
  JEQ    .L33
  JMP    .L34
.L27:
.L28:
.L29:
.L30:
.L31:
.L32:
.L33:
  MOV    A, 2
  LD     B, [SP, 22] ; new
  ST.B   [B, 0], A ; .type
  LD     A, [SP, 0] ; input
  LD     B, [SP, 4] ; i
  ADD    C, B, 1
  ST     [SP, 4], C ; i
  LD.B   A, [A, B]
  LD     B, [SP, 22] ; new
  ST.B   [B, 1], A ; .sym
  JMP    .L26
.L34:
  LDI    A, =.S16
  LD     B, [SP, 0] ; input
  LD     C, [SP, 4] ; i
  LD.B   B, [B, C]
  CALL   printf
  LD     A, [SP, 22] ; new
  CALL   free
  MOV    A, 0
  ST     [SP, 22], A ; new
  MOV    A, 200
  LDI    B, =errno
  ST     [B], A
  LDI    A, =jmp
  MOV    B, 1
  CALL   longjmp
.L26:
.L22:
  LD.H   A, [SP, 20] ; line
  LD     B, [SP, 22] ; new
  ST.H   [B, 5], A ; .line
  LD     A, [SP, 12] ; head
  CMP    A, 0
  JNE    .L36
  LD     A, [SP, 22] ; new
  ST     [SP, 16], A ; tail
  ST     [SP, 12], A ; head
  JMP    .L35
.L36:
  LD     A, [SP, 22] ; new
  LD     B, [SP, 16] ; tail
  ST     [B, 7], A ; .next
  LD     A, [SP, 22] ; new
  ST     [SP, 16], A ; tail
.L35:
.L19:
  JMP    .L17
.L18:
  MOV    A, 11
  CALL   malloc
  ST     [SP, 22], A ; end
  MOV    A, 4
  LD     B, [SP, 22] ; end
  ST.B   [B, 0], A ; .type
  MOV.B  A, '\0'
  LD     B, [SP, 22] ; end
  ST.B   [B, 1], A ; .sym
  LD.H   A, [SP, 20] ; line
  LD     B, [SP, 22] ; end
  ST.H   [B, 5], A ; .line
  MOV    A, 0
  LD     B, [SP, 22] ; end
  ST     [B, 7], A ; .next
  LD     A, [SP, 22] ; end
  LD     B, [SP, 16] ; tail
  ST     [B, 7], A ; .next
  LD     A, [SP, 12] ; head
.L16:
  ADD    SP, 26
  POP    B, C, D, E, PC
printTokens:
  PUSH   B, LR
  SUB    SP, 4
  ST     [SP, 0], A ; head
.L37:
  LD     A, [SP, 0] ; head
  CMP    A, 0
  JEQ    .L39
  LD     A, [SP, 0] ; head
  LD.B   A, [A, 0] ; .type
  CMP.B  A, 0
  JEQ    .L42
  CMP.B  A, 1
  JEQ    .L43
  CMP.B  A, 2
  JEQ    .L44
  JMP    .L41
.L42:
  LDI    A, =.S17
  LD     B, [SP, 0] ; head
  LD     B, [B, 1] ; .lexeme
  CALL   printf
  JMP    .L41
.L43:
  LDI    A, =.S18
  LD     B, [SP, 0] ; head
  LD     B, [B, 1] ; .lexeme
  CALL   printf
  JMP    .L41
.L44:
  LDI    A, =.S19
  LD     B, [SP, 0] ; head
  LD.B   B, [B, 1] ; .sym
  CALL   printf
.L41:
.L38:
  LD     A, [SP, 0] ; head
  LD     A, [A, 7] ; .next
  ST     [SP, 0], A ; head
  JMP    .L37
.L39:
  ADD    SP, 4
  POP    B, PC
allocNumber:
  PUSH   B, LR
  SUB    SP, 8
  ST     [SP, 0], A ; token
  MOV    A, 9
  CALL   malloc
  ST     [SP, 4], A ; node
  MOV    A, 0
  LD     B, [SP, 4] ; node
  ST.B   [B, 0], A ; .type
  LD     A, [SP, 0] ; token
  LD     B, [SP, 4] ; node
  ST     [B, 1], A ; .token
  LD     A, [SP, 0] ; token
  LD     A, [A, 1] ; .lexeme
  CALL   atoi
  LD     B, [SP, 4] ; node
  ST     [B, 5], A ; .num
  LD     A, [SP, 4] ; node
.L45:
  ADD    SP, 8
  POP    B, PC
allocVariable:
  PUSH   B, LR
  SUB    SP, 8
  ST     [SP, 0], A ; token
  MOV    A, 9
  CALL   malloc
  ST     [SP, 4], A ; node
  MOV    A, 1
  LD     B, [SP, 4] ; node
  ST.B   [B, 0], A ; .type
  LD     A, [SP, 0] ; token
  LD     B, [SP, 4] ; node
  ST     [B, 1], A ; .token
  LD     A, [SP, 0] ; token
  LD     A, [A, 1] ; .lexeme
  LD     B, [SP, 4] ; node
  ST     [B, 5], A ; .name
  LD     A, [SP, 4] ; node
.L46:
  ADD    SP, 8
  POP    B, PC
add_:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  ADD    A, B
.L47:
  ADD    SP, 8
  RET
sub_:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  SUB    A, B
.L48:
  ADD    SP, 8
  RET
mul_:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  MUL    A, B
.L49:
  ADD    SP, 8
  RET
div_:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  DIV    A, B
.L50:
  ADD    SP, 8
  RET
allocBinary:
  PUSH   LR
  SUB    SP, 16
  ST     [SP, 0], A ; token
  ST     [SP, 4], B ; left
  ST     [SP, 8], C ; right
  MOV    A, 9
  CALL   malloc
  ST     [SP, 12], A ; node
  MOV    A, 2
  LD     B, [SP, 12] ; node
  ST.B   [B, 0], A ; .type
  LD     A, [SP, 0] ; token
  LD     B, [SP, 12] ; node
  ST     [B, 1], A ; .token
  MOV    A, 12
  CALL   malloc
  LD     B, [SP, 12] ; node
  ST     [B, 5], A ; .binary
  LD     A, [SP, 12] ; node
  LD     A, [A, 1] ; .token
  LD.B   A, [A, 1] ; .sym
  SUB.B  B, A, '*'
  CMP.B  B, 5
  JHI    .L59
  LDI    A, =.L54
  SHL    B, 2
  LD     PC, [A, B]
.L56:
  LDI    A, =add_
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 0], A ; .op
  JMP    .L53
.L57:
  LDI    A, =sub_
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 0], A ; .op
  JMP    .L53
.L55:
  LDI    A, =mul_
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 0], A ; .op
  JMP    .L53
.L58:
  LDI    A, =div_
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 0], A ; .op
.L59:
.L53:
  LD     A, [SP, 4] ; left
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 4], A ; .left
  LD     A, [SP, 8] ; right
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 8], A ; .right
  LD     A, [SP, 12] ; node
.L51:
  ADD    SP, 16
  POP    PC
allocAssign:
  PUSH   LR
  SUB    SP, 16
  ST     [SP, 0], A ; token
  ST     [SP, 4], B ; left
  ST     [SP, 8], C ; right
  MOV    A, 9
  CALL   malloc
  ST     [SP, 12], A ; node
  MOV    A, 3
  LD     B, [SP, 12] ; node
  ST.B   [B, 0], A ; .type
  LD     A, [SP, 0] ; token
  LD     B, [SP, 12] ; node
  ST     [B, 1], A ; .token
  MOV    A, 12
  CALL   malloc
  LD     B, [SP, 12] ; node
  ST     [B, 5], A ; .binary
  MOV    A, 0
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 0], A ; .op
  LD     A, [SP, 4] ; left
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 4], A ; .left
  LD     A, [SP, 8] ; right
  LD     B, [SP, 12] ; node
  LD     B, [B, 5] ; .binary
  ST     [B, 8], A ; .right
  LD     A, [SP, 12] ; node
.L60:
  ADD    SP, 16
  POP    PC
freeNode:
  PUSH   LR
  SUB    SP, 4
  ST     [SP, 0], A ; node
  CMP    A, 0
  JEQ    .L61
  LD     A, [SP, 0] ; node
  LD.B   A, [A, 0] ; .type
  CMP.B  A, 2
  JEQ    .L64
  CMP.B  A, 3
  JEQ    .L65
  JMP    .L63
.L64:
.L65:
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .binary
  LD     A, [A, 4] ; .left
  CALL   freeNode
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .binary
  LD     A, [A, 8] ; .right
  CALL   freeNode
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .binary
  CALL   free
.L63:
  LD     A, [SP, 0] ; node
  CALL   free
.L61:
  ADD    SP, 4
  POP    PC
eval:
  PUSH   B, C, LR
  SUB    SP, 8
  ST     [SP, 0], A ; node
  LD.B   A, [A, 0] ; .type
  SUB.B  B, A, 0
  CMP.B  B, 3
  JHI    .L74
  LDI    A, =.L69
  SHL    B, 2
  LD     PC, [A, B]
.L70:
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .num
  JMP    .L66
.L71:
  LDI    A, =env
  LD     A, [A]
  LD     B, [SP, 0] ; node
  LD     B, [B, 5] ; .name
  CALL   IntMap_get
  ST     [SP, 4], A ; var
  CMP    A, 0
  JNE    .L75
  LDI    A, =.S20
  LD     B, [SP, 0] ; node
  LD     B, [B, 5] ; .name
  CALL   printf
  MOV    A, 201
  LDI    B, =errno
  ST     [B], A
  LDI    A, =jmp
  MOV    B, 1
  CALL   longjmp
.L75:
  LD     A, [SP, 4] ; var
  LD     A, [A, 4] ; .value
  JMP    .L66
.L72:
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .binary
  LD     A, [A, 4] ; .left
  CALL   eval
  MOV    C, A
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .binary
  LD     A, [A, 8] ; .right
  CALL   eval
  MOV    B, A
  MOV    A, C
  LD     C, [SP, 0] ; node
  LD     C, [C, 5] ; .binary
  LD     C, [C, 0] ; .op
  CALL   C
  JMP    .L66
.L73:
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .binary
  LD     A, [A, 8] ; .right
  CALL   eval
  ST     [SP, 4], A ; value
  LDI    A, =env
  LD     A, [A]
  LD     B, [SP, 0] ; node
  LD     B, [B, 5] ; .binary
  LD     B, [B, 4] ; .left
  LD     B, [B, 5] ; .name
  LD     C, [SP, 4] ; value
  CALL   IntMap_set
  LD     A, [SP, 4] ; value
.L74:
.L68:
.L66:
  ADD    SP, 8
  POP    B, C, PC
printNode:
  PUSH   B, LR
  SUB    SP, 4
  ST     [SP, 0], A ; node
  LD.B   A, [A, 0] ; .type
  CMP.B  A, 0
  JEQ    .L78
  CMP.B  A, 1
  JEQ    .L79
  CMP.B  A, 2
  JEQ    .L80
  JMP    .L77
.L78:
  LDI    A, =.S21
  LD     B, [SP, 0] ; node
  LD     B, [B, 5] ; .num
  CALL   printf
  JMP    .L77
.L79:
  LDI    A, =.S22
  LD     B, [SP, 0] ; node
  LD     B, [B, 5] ; .name
  CALL   printf
  JMP    .L77
.L80:
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .binary
  LD     A, [A, 4] ; .left
  CALL   printNode
  LD     A, [SP, 0] ; node
  LD     A, [A, 5] ; .binary
  LD     A, [A, 8] ; .right
  CALL   printNode
  LDI    A, =.S23
  LD     B, [SP, 0] ; node
  LD     B, [B, 1] ; .token
  LD.B   B, [B, 1] ; .sym
  CALL   printf
.L77:
  ADD    SP, 4
  POP    B, PC
next:
  PUSH   B
  SUB    SP, 4
  LDI    A, =current
  LD     A, [A]
  ST     [SP, 0], A ; next
  LDI    A, =current
  LD     B, [A]
  LD     B, [B, 7] ; .next
  ST     [A], B
  LD     A, [SP, 0] ; next
.L81:
  ADD    SP, 4
  POP    B
  RET
peekToken:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; type
  LDI    A, =current
  LD     A, [A]
  LD.B   A, [A, 0] ; .type
  LD.B   B, [SP, 0] ; type
  CMP.B  A, B
  MOVEQ  A, 1
  MOVNE  A, 0
.L82:
  ADD    SP, 1
  POP    B
  RET
peek:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; sym
  LDI    A, =current
  LD     A, [A]
  LD.B   A, [A, 1] ; .sym
  LD.B   B, [SP, 0] ; sym
  CMP.B  A, B
  MOVEQ  A, 1
  MOVNE  A, 0
.L83:
  ADD    SP, 1
  POP    B
  RET
accept:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; sym
  CALL   peek
  CMP.B  A, 0
  JEQ    .L85
  CALL   next
  MOV.B  A, 1
  JMP    .L84
.L85:
  MOV.B  A, 0
.L84:
  ADD    SP, 1
  POP    PC
expectToken:
  PUSH   B, C, LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; token
  CALL   peekToken
  CMP.B  A, 0
  JEQ    .L87
  CALL   next
  JMP    .L86
.L87:
  LDI    A, =.S24
  LDI    B, =TokenTypeMap
  LD.B   C, [SP, 0] ; token
  SHL    C, 2
  LD     B, [B, C]
  CALL   printf
  MOV    A, 202
  LDI    B, =errno
  ST     [B], A
  LDI    A, =jmp
  MOV    B, 1
  CALL   longjmp
.L86:
  ADD    SP, 1
  POP    B, C, PC
expect:
  PUSH   B, LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; sym
  CALL   peek
  CMP.B  A, 0
  JEQ    .L89
  CALL   next
  JMP    .L88
.L89:
  LDI    A, =.S25
  LD.B   B, [SP, 0] ; sym
  CALL   printf
  MOV    A, 202
  LDI    B, =errno
  ST     [B], A
  LDI    A, =jmp
  MOV    B, 1
  CALL   longjmp
.L88:
  ADD    SP, 1
  POP    B, PC
factor:
  PUSH   B, LR
  SUB    SP, 4
  MOV    A, 0
  CALL   peekToken
  CMP.B  A, 0
  JEQ    .L92
  CALL   next
  CALL   allocNumber
  ST     [SP, 0], A ; factor
  JMP    .L91
.L92:
  MOV    A, 1
  CALL   peekToken
  CMP.B  A, 0
  JEQ    .L93
  CALL   next
  CALL   allocVariable
  ST     [SP, 0], A ; factor
  JMP    .L91
.L93:
  MOV.B  A, '('
  CALL   accept
  CMP.B  A, 0
  JEQ    .L94
  CALL   expr
  ST     [SP, 0], A ; factor
  MOV.B  A, ')'
  CALL   expect
  JMP    .L91
.L94:
  LDI    A, =.S26
  CALL   printf
  MOV    A, 202
  LDI    B, =errno
  ST     [B], A
  LDI    A, =jmp
  MOV    B, 1
  CALL   longjmp
.L91:
  LD     A, [SP, 0] ; factor
.L90:
  ADD    SP, 4
  POP    B, PC
term:
  PUSH   B, C, D, LR
  SUB    SP, 8
  CALL   factor
  ST     [SP, 0], A ; term
.L96:
  MOV.B  A, '*'
  CALL   peek
  CMP.B  A, 0
  JNE    .L98
  MOV.B  A, '/'
  CALL   peek
  CMP.B  A, 0
  JEQ    .L97
.L98:
  CALL   next
  ST     [SP, 4], A ; token
  LD     D, [SP, 4] ; token
  LD     B, [SP, 0] ; term
  CALL   factor
  MOV    C, A
  MOV    A, D
  CALL   allocBinary
  ST     [SP, 0], A ; term
  JMP    .L96
.L97:
  LD     A, [SP, 0] ; term
.L95:
  ADD    SP, 8
  POP    B, C, D, PC
expr:
  PUSH   B, C, D, LR
  SUB    SP, 8
  CALL   term
  ST     [SP, 0], A ; expr
.L100:
  MOV.B  A, '+'
  CALL   peek
  CMP.B  A, 0
  JNE    .L102
  MOV.B  A, '-'
  CALL   peek
  CMP.B  A, 0
  JEQ    .L101
.L102:
  CALL   next
  ST     [SP, 4], A ; token
  LD     D, [SP, 4] ; token
  LD     B, [SP, 0] ; expr
  CALL   term
  MOV    C, A
  MOV    A, D
  CALL   allocBinary
  ST     [SP, 0], A ; expr
  JMP    .L100
.L101:
  LD     A, [SP, 0] ; expr
.L99:
  ADD    SP, 8
  POP    B, C, D, PC
assign:
  PUSH   B, C, D, LR
  SUB    SP, 8
  CALL   expr
  ST     [SP, 0], A ; assign
  MOV.B  A, '='
  CALL   peek
  CMP.B  A, 0
  JEQ    .L104
  LD     A, [SP, 0] ; assign
  LD.B   A, [A, 0] ; .type
  CMP    A, 1
  JEQ    .L105
  LDI    A, =.S27
  CALL   printf
  MOV    A, 203
  LDI    B, =errno
  ST     [B], A
  LD     A, [SP, 0] ; assign
  CALL   freeNode
  MOV    A, 0
  ST     [SP, 0], A ; assign
  LDI    A, =jmp
  MOV    B, 1
  CALL   longjmp
.L105:
  CALL   next
  ST     [SP, 4], A ; token
  LD     D, [SP, 4] ; token
  LD     B, [SP, 0] ; assign
  CALL   expr
  MOV    C, A
  MOV    A, D
  CALL   allocAssign
  ST     [SP, 0], A ; assign
.L104:
  LD     A, [SP, 0] ; assign
.L103:
  ADD    SP, 8
  POP    B, C, D, PC
parse:
  PUSH   B, LR
  SUB    SP, 8
  ST     [SP, 0], A ; head
  LDI    B, =current
  ST     [B], A
  CALL   assign
  ST     [SP, 4], A ; root
  MOV    A, 4
  CALL   expectToken
  LD     A, [SP, 4] ; root
.L106:
  ADD    SP, 8
  POP    B, PC
_allocIntMap:
  PUSH   B, LR
  SUB    SP, 8
  ST     [SP, 0], A ; size
  MOV    A, 12
  CALL   malloc
  ST     [SP, 4], A ; map
  LD     A, [SP, 0] ; size
  MOV    B, 4
  CALL   calloc
  LD     B, [SP, 4] ; map
  ST     [B, 0], A ; .data
  MOV    A, 0
  LD     B, [SP, 4] ; map
  ST     [B, 4], A ; .size
  LD     A, [SP, 0] ; size
  LD     B, [SP, 4] ; map
  ST     [B, 8], A ; .capacity
  LD     A, [SP, 4] ; map
.L107:
  ADD    SP, 8
  POP    B, PC
hash:
  PUSH   B, C
  SUB    SP, 8
  ST     [SP, 0], A ; key
  MOV    A, 0
  ST     [SP, 4], A ; hash
.L109:
  LD     A, [SP, 0] ; key
  LD.B   A, [A]
  CMP.B  A, '\0'
  JEQ    .L111
  LD     A, [SP, 0] ; key
  LD.B   A, [A]
  MOV    B, 31
  LD     C, [SP, 4] ; hash
  MUL    B, C
  ADD    A, B
  ST     [SP, 4], A ; hash
.L110:
  LD     A, [SP, 0] ; key
  ADD    A, 1
  ST     [SP, 0], A ; key
  JMP    .L109
.L111:
  LD     A, [SP, 4] ; hash
.L108:
  ADD    SP, 8
  POP    B, C
  RET
IntMap_hash:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; map
  ST     [SP, 4], B ; key
  LD     A, [SP, 4] ; key
  CALL   hash
  LD     B, [SP, 0] ; map
  LD     B, [B, 8] ; .capacity
  MOD    A, B
.L112:
  ADD    SP, 8
  POP    PC
IntMap_get:
  PUSH   C, LR
  SUB    SP, 12
  ST     [SP, 0], A ; map
  ST     [SP, 4], B ; key
  LD     A, [SP, 0] ; map
  CMP    A, 0
  JEQ    .L114
  LD     A, [SP, 0] ; map
  LD     C, [A, 0] ; .data
  LD     B, [SP, 4] ; key
  CALL   IntMap_hash
  SHL    A, 2
  LD     A, [C, A]
  ST     [SP, 8], A ; pair
.L115:
  LD     A, [SP, 8] ; pair
  CMP    A, 0
  JEQ    .L117
  LD     A, [SP, 4] ; key
  LD     B, [SP, 8] ; pair
  LD     B, [B, 0] ; .key
  CALL   strcmp
  CMP    A, 0
  JNE    .L118
  LD     A, [SP, 8] ; pair
  JMP    .L113
.L118:
.L116:
  LD     A, [SP, 8] ; pair
  LD     A, [A, 8] ; .next
  ST     [SP, 8], A ; pair
  JMP    .L115
.L117:
.L114:
  MOV    A, 0
.L113:
  ADD    SP, 12
  POP    C, PC
IntMap_in:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; map
  ST     [SP, 4], B ; key
  LD     A, [SP, 0] ; map
  LD     B, [SP, 4] ; key
  CALL   IntMap_get
  CMP    A, 0
  MOVNE  A, 1
  MOVEQ  A, 0
.L119:
  ADD    SP, 8
  POP    PC
_IntMap_rehash:
  PUSH   C, LR
  SUB    SP, 8
  ST     [SP, 0], A ; map
  ST     [SP, 4], B ; pair
.L120:
  LD     A, [SP, 4] ; pair
  CMP    A, 0
  JEQ    .L121
  LD     A, [SP, 0] ; map
  LD     C, [SP, 4] ; pair
  LD     B, [C, 0] ; .key
  LD     C, [C, 4] ; .value
  CALL   IntMap_set
  LD     A, [SP, 4] ; pair
  LD     A, [A, 8] ; .next
  ST     [SP, 4], A ; pair
  JMP    .L120
.L121:
  ADD    SP, 8
  POP    C, PC
_IntMap_resize:
  PUSH   B, C, LR
  SUB    SP, 12
  ST     [SP, 0], A ; old
  MOV    A, 2
  LD     B, [SP, 0] ; old
  LD     B, [B, 8] ; .capacity
  MUL    A, B
  CALL   _allocIntMap
  ST     [SP, 4], A ; map
  MOV    A, 0
  ST     [SP, 8], A ; i
.L123:
  LD     A, [SP, 8] ; i
  LD     B, [SP, 0] ; old
  LD     B, [B, 8] ; .capacity
  CMP    A, B
  JGE    .L125
  LD     A, [SP, 4] ; map
  LD     B, [SP, 0] ; old
  LD     B, [B, 0] ; .data
  LD     C, [SP, 8] ; i
  SHL    C, 2
  LD     B, [B, C]
  CALL   _IntMap_rehash
.L124:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
  JMP    .L123
.L125:
  LD     A, [SP, 0] ; old
  LD     A, [A, 0] ; .data
  CALL   free
  LD     A, [SP, 0] ; old
  CALL   free
  LD     A, [SP, 4] ; map
.L122:
  ADD    SP, 12
  POP    B, C, PC
IntMap_set:
  PUSH   LR
  SUB    SP, 20
  ST     [SP, 0], A ; map
  ST     [SP, 4], B ; key
  ST     [SP, 8], C ; value
  LD     A, [SP, 0] ; map
  CMP    A, 0
  JEQ    .L126
  LD     B, [SP, 0] ; map
  LD     A, [B, 4] ; .size
  LD     B, [B, 8] ; .capacity
  CMP    A, B
  JNE    .L127
  LD     A, [SP, 0] ; map
  CALL   _IntMap_resize
  ST     [SP, 0], A ; map
.L127:
  LD     A, [SP, 0] ; map
  LD     B, [SP, 4] ; key
  CALL   IntMap_in
  CMP.B  A, 0
  JNE    .L128
  MOV    A, 12
  CALL   malloc
  ST     [SP, 12], A ; pair
  LD     A, [SP, 4] ; key
  CALL   strdup
  LD     B, [SP, 12] ; pair
  ST     [B, 0], A ; .key
  LD     A, [SP, 0] ; map
  LD     B, [SP, 4] ; key
  CALL   IntMap_hash
  ST     [SP, 16], A ; h
  LD     A, [SP, 0] ; map
  LD     A, [A, 0] ; .data
  LD     B, [SP, 16] ; h
  SHL    B, 2
  LD     A, [A, B]
  CMP    A, 0
  JNE    .L130
  MOV    A, 0
  LD     B, [SP, 12] ; pair
  ST     [B, 8], A ; .next
  LD     A, [SP, 12] ; pair
  LD     B, [SP, 0] ; map
  LD     B, [B, 0] ; .data
  LD     C, [SP, 16] ; h
  SHL    C, 2
  ST     [B, C], A
  JMP    .L129
.L130:
  LD     A, [SP, 0] ; map
  LD     A, [A, 0] ; .data
  LD     B, [SP, 16] ; h
  SHL    B, 2
  LD     A, [A, B]
  LD     A, [A, 8] ; .next
  LD     B, [SP, 12] ; pair
  ST     [B, 8], A ; .next
  LD     A, [SP, 12] ; pair
  LD     B, [SP, 0] ; map
  LD     B, [B, 0] ; .data
  LD     C, [SP, 16] ; h
  SHL    C, 2
  LD     B, [B, C]
  ST     [B, 8], A ; .next
.L129:
  LD     A, [SP, 0] ; map
  LD     B, [A, 4] ; .size
  ADD    B, 1
  ST     [A, 4], B ; .size
.L128:
  LD     A, [SP, 0] ; map
  LD     B, [SP, 4] ; key
  CALL   IntMap_get
  ST     [SP, 12], A ; pair
  LD     A, [SP, 8] ; value
  LD     B, [SP, 12] ; pair
  ST     [B, 4], A ; .value
.L126:
  ADD    SP, 20
  POP    PC
IntMap_del:
  PUSH   C, LR
  SUB    SP, 20
  ST     [SP, 0], A ; map
  ST     [SP, 4], B ; key
  LD     A, [SP, 0] ; map
  CMP    A, 0
  JEQ    .L131
  LD     A, [SP, 0] ; map
  LD     B, [SP, 4] ; key
  CALL   IntMap_in
  CMP.B  A, 0
  JEQ    .L132
  LD     A, [SP, 0] ; map
  LD     B, [SP, 4] ; key
  CALL   IntMap_hash
  ST     [SP, 12], A ; h
  LD     A, [SP, 4] ; key
  LD     B, [SP, 0] ; map
  LD     B, [B, 0] ; .data
  LD     C, [SP, 12] ; h
  SHL    C, 2
  LD     B, [B, C]
  LD     B, [B, 0] ; .key
  CALL   strcmp
  CMP    A, 0
  JNE    .L134
  LD     A, [SP, 0] ; map
  LD     A, [A, 0] ; .data
  LD     B, [SP, 12] ; h
  SHL    B, 2
  LD     A, [A, B]
  ST     [SP, 8], A ; pair
  LD     A, [A, 8] ; .next
  LD     B, [SP, 0] ; map
  LD     B, [B, 0] ; .data
  LD     C, [SP, 12] ; h
  SHL    C, 2
  ST     [B, C], A
  JMP    .L133
.L134:
  LD     A, [SP, 0] ; map
  LD     A, [A, 0] ; .data
  LD     B, [SP, 12] ; h
  SHL    B, 2
  LD     A, [A, B]
  ST     [SP, 16], A ; prev
  LD     A, [A, 8] ; .next
  ST     [SP, 8], A ; pair
.L135:
  LD     A, [SP, 8] ; pair
  CMP    A, 0
  JEQ    .L137
  LD     A, [SP, 4] ; key
  LD     B, [SP, 8] ; pair
  LD     B, [B, 0] ; .key
  CALL   strcmp
  CMP    A, 0
  JNE    .L138
  LD     A, [SP, 8] ; pair
  LD     A, [A, 8] ; .next
  LD     B, [SP, 16] ; prev
  ST     [B, 8], A ; .next
.L138:
.L136:
  LD     A, [SP, 8] ; pair
  ST     [SP, 16], A ; prev
  LD     A, [A, 8] ; .next
  ST     [SP, 8], A ; pair
  JMP    .L135
.L137:
.L133:
  LD     A, [SP, 8] ; pair
  LD     A, [A, 0] ; .key
  CALL   free
  LD     A, [SP, 8] ; pair
  CALL   free
  LD     A, [SP, 0] ; map
  LD     B, [A, 4] ; .size
  SUB    B, 1
  ST     [A, 4], B ; .size
.L132:
.L131:
  ADD    SP, 20
  POP    C, PC
freePairs:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; pair
.L139:
  LD     A, [SP, 0] ; pair
  CMP    A, 0
  JEQ    .L140
  LD     A, [SP, 0] ; pair
  ST     [SP, 4], A ; temp
  LD     A, [SP, 0] ; pair
  LD     A, [A, 8] ; .next
  ST     [SP, 0], A ; pair
  LD     A, [SP, 4] ; temp
  LD     A, [A, 0] ; .key
  CALL   free
  LD     A, [SP, 4] ; temp
  CALL   free
  JMP    .L139
.L140:
  ADD    SP, 8
  POP    PC
freeIntMap:
  PUSH   B, LR
  SUB    SP, 8
  ST     [SP, 0], A ; map
  CMP    A, 0
  JEQ    .L141
  MOV    A, 0
  ST     [SP, 4], A ; i
.L142:
  LD     A, [SP, 4] ; i
  LD     B, [SP, 0] ; map
  LD     B, [B, 8] ; .capacity
  CMP    A, B
  JGE    .L144
  LD     A, [SP, 0] ; map
  LD     A, [A, 0] ; .data
  LD     B, [SP, 4] ; i
  SHL    B, 2
  LD     A, [A, B]
  CALL   freePairs
.L143:
  LD     A, [SP, 4] ; i
  ADD    A, 1
  ST     [SP, 4], A ; i
  JMP    .L142
.L144:
.L141:
  LD     A, [SP, 0] ; map
  LD     A, [A, 0] ; .data
  CALL   free
  LD     A, [SP, 0] ; map
  CALL   free
  ADD    SP, 8
  POP    B, PC
isupper:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV.B  A, 'A'
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L146
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'Z'
  JGT    .L146
  MOV    A, 1
  JMP    .L147
.L146:
  MOV    A, 0
.L145:
.L147:
  ADD    SP, 1
  POP    B
  RET
islower:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV.B  A, 'a'
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L149
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'z'
  JGT    .L149
  MOV    A, 1
  JMP    .L150
.L149:
  MOV    A, 0
.L148:
.L150:
  ADD    SP, 1
  POP    B
  RET
isalpha:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   islower
  CMP    A, 0
  JNE    .L152
  LD.B   A, [SP, 0] ; c
  CALL   isupper
  CMP    A, 0
  JEQ    .L153
.L152:
  MOV    A, 1
  JMP    .L154
.L153:
  MOV    A, 0
.L151:
.L154:
  ADD    SP, 1
  POP    PC
iscntrl:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV    A, 0
  LD.B   B, [SP, 0] ; c
  CMP    A, B
  JGT    .L156
  LD.B   A, [SP, 0] ; c
  CMP    A, 32
  JGE    .L156
  MOV    A, 1
  JMP    .L157
.L156:
  MOV    A, 0
.L155:
.L157:
  ADD    SP, 1
  POP    B
  RET
isdigit:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV.B  A, '0'
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L159
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '9'
  JGT    .L159
  MOV    A, 1
  JMP    .L160
.L159:
  MOV    A, 0
.L158:
.L160:
  ADD    SP, 1
  POP    B
  RET
isalnum:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isalpha
  CMP    A, 0
  JNE    .L162
  LD.B   A, [SP, 0] ; c
  CALL   isdigit
  CMP    A, 0
  JEQ    .L163
.L162:
  MOV    A, 1
  JMP    .L164
.L163:
  MOV    A, 0
.L161:
.L164:
  ADD    SP, 1
  POP    PC
isspace:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP.B  A, ' '
  JEQ    .L166
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '\t'
  JEQ    .L166
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '\n'
  JNE    .L167
.L166:
  MOV    A, 1
  JMP    .L168
.L167:
  MOV    A, 0
.L165:
.L168:
  ADD    SP, 1
  RET
isxdigit:
  PUSH   B, LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isdigit
  CMP    A, 0
  JNE    .L170
  MOV.B  A, 'A'
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L173
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'F'
  JLE    .L170
.L173:
  MOV.B  A, 'a'
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L171
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'f'
  JGT    .L171
.L170:
  MOV    A, 1
  JMP    .L172
.L171:
  MOV    A, 0
.L169:
.L172:
  ADD    SP, 1
  POP    B, PC
tolower:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isupper
  CMP    A, 0
  JEQ    .L175
  LD.B   A, [SP, 0] ; c
  ADD.B  A, 'a'
  SUB.B  A, 'A'
  JMP    .L174
.L175:
  LD.B   A, [SP, 0] ; c
.L174:
  ADD    SP, 1
  POP    PC
toupper:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   islower
  CMP    A, 0
  JEQ    .L177
  LD.B   A, [SP, 0] ; c
  SUB.B  A, 'a'
  SUB.B  A, 'A'
  JMP    .L176
.L177:
  LD.B   A, [SP, 0] ; c
.L176:
  ADD    SP, 1
  POP    PC
isgraph:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV.B  A, ' '
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGE    .L179
  LD.B   A, [SP, 0] ; c
  CMP    A, 127
  JGE    .L179
  MOV    A, 1
  JMP    .L180
.L179:
  MOV    A, 0
.L178:
.L180:
  ADD    SP, 1
  POP    B
  RET
isprint:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV.B  A, ' '
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L182
  LD.B   A, [SP, 0] ; c
  CMP    A, 127
  JGE    .L182
  MOV    A, 1
  JMP    .L183
.L182:
  MOV    A, 0
.L181:
.L183:
  ADD    SP, 1
  POP    B
  RET
ispunct:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isgraph
  CMP    A, 0
  JEQ    .L185
  LD.B   A, [SP, 0] ; c
  CALL   isalnum
  CMP    A, 0
  JNE    .L185
  MOV    A, 1
  JMP    .L186
.L185:
  MOV    A, 0
.L184:
.L186:
  ADD    SP, 1
  POP    PC
fgetc:
  PUSH   B, C
  SUB    SP, 5
  ST     [SP, 0], A ; stream
.L188:
  LD     B, [SP, 0] ; stream
  LD     A, [B, 4] ; .read
  LD     B, [B, 8] ; .write
  CMP    A, B
  JNE    .L189
  JMP    .L188
.L189:
  LD     B, [SP, 0] ; stream
  LD     A, [B, 0] ; .buffer
  LD     B, [B, 4] ; .read
  LD.B   A, [A, B]
  ST.B   [SP, 4], A ; c
  LD     A, [SP, 0] ; stream
  LD     B, [A, 4] ; .read
  ADD    B, 1
  LD     C, [A, 12] ; .size
  MOD    B, C
  ST     [A, 4], B ; .read
  LD.B   A, [SP, 4] ; c
.L187:
  ADD    SP, 5
  POP    B, C
  RET
getchar:
  PUSH   B, C
  SUB    SP, 1
.L191:
  LDI    A, =stdin
  LD     B, [A]
  LD     A, [B, 4] ; .read
  LD     B, [B, 8] ; .write
  CMP    A, B
  JNE    .L192
  JMP    .L191
.L192:
  LDI    A, =stdin
  LD     B, [A]
  LD     A, [B, 0] ; .buffer
  LD     B, [B, 4] ; .read
  LD.B   A, [A, B]
  ST.B   [SP, 0], A ; c
  LDI    A, =stdin
  LD     A, [A]
  LD     B, [A, 4] ; .read
  ADD    B, 1
  LD     C, [A, 12] ; .size
  MOD    B, C
  ST     [A, 4], B ; .read
  LD.B   A, [SP, 0] ; c
.L190:
  ADD    SP, 1
  POP    B, C
  RET
fgets:
  PUSH   LR
  SUB    SP, 17
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  ST     [SP, 8], C ; stream
  MOV    A, 0
  ST     [SP, 12], A ; i
  LD     A, [SP, 4] ; n
  CMP    A, 0
  JLS    .L194
.L195:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 4] ; n
  SUB    B, 1
  CMP    A, B
  JCS    .L196
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 16], A ; c
  CMP.B  A, 0
  JEQ    .L196
  LD.B   A, [SP, 16] ; c
  CMP.B  A, '\n'
  JEQ    .L196
  LD.B   A, [SP, 16] ; c
  CMP.B  A, '\b'
  JNE    .L198
  LD     A, [SP, 12] ; i
  CMP    A, 0
  JLS    .L198
  LD     A, [SP, 12] ; i
  SUB    A, 1
  ST     [SP, 12], A ; i
  JMP    .L197
.L198:
  LD.B   A, [SP, 16] ; c
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ST.B   [B, C], A
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
.L197:
  JMP    .L195
.L196:
.L194:
  MOV.B  A, '\0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ST.B   [B, C], A
  LD     A, [SP, 0] ; s
.L193:
  ADD    SP, 17
  POP    PC
gets:
  PUSH   C, LR
  SUB    SP, 8
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; n
  LDI    C, =stdin
  LD     C, [C]
  CALL   fgets
.L199:
  ADD    SP, 8
  POP    C, PC
fputc:
  PUSH   C
  SUB    SP, 5
  ST.B   [SP, 0], A ; c
  ST     [SP, 1], B ; stream
  LD.B   A, [SP, 0] ; c
  LD     C, [SP, 1] ; stream
  LD     B, [C, 0] ; .buffer
  LD     C, [C, 8] ; .write
  ST.B   [B, C], A
  LD     A, [SP, 1] ; stream
  LD     B, [A, 8] ; .write
  ADD    B, 1
  LD     C, [A, 12] ; .size
  MOD    B, C
  ST     [A, 8], B ; .write
  MOV    A, 0
.L200:
  ADD    SP, 5
  POP    C
  RET
putchar:
  PUSH   B, C
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  LDI    B, =stdout
  LD     C, [B]
  LD     B, [C, 0] ; .buffer
  LD     C, [C, 8] ; .write
  ST.B   [B, C], A
  MOV    A, 0
.L201:
  ADD    SP, 1
  POP    B, C
  RET
fputs:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; stream
.L203:
  LD     A, [SP, 0] ; s
  LD.B   A, [A]
  CMP.B  A, '\0'
  JEQ    .L204
  LD     A, [SP, 0] ; s
  LD.B   A, [A]
  LD     B, [SP, 4] ; stream
  CALL   fputc
  LD     A, [SP, 0] ; s
  ADD    A, 1
  ST     [SP, 0], A ; s
  JMP    .L203
.L204:
  MOV    A, 0
.L202:
  ADD    SP, 8
  POP    PC
puts:
  PUSH   B, LR
  SUB    SP, 4
  ST     [SP, 0], A ; s
  LDI    B, =stdout
  LD     B, [B]
  CALL   fputs
  MOV.B  A, '\n'
  CALL   putchar
  MOV    A, 0
.L205:
  ADD    SP, 4
  POP    B, PC
uprint:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; n
  LD     A, [SP, 4] ; n
  DIV    A, 10
  CMP    A, 0
  JEQ    .L206
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 4] ; n
  DIV    B, 10
  CALL   uprint
.L206:
  LD     A, [SP, 4] ; n
  MOD    A, 10
  ADD    A, '0'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  ADD    SP, 8
  POP    PC
oprint:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; n
  LD     A, [SP, 4] ; n
  SHR    A, 3
  CMP    A, 0
  JEQ    .L207
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 4] ; n
  SHR    B, 3
  CALL   oprint
.L207:
  LD     A, [SP, 4] ; n
  AND    A, 7
  ADD    A, '0'
  CALL   putchar
  ADD    SP, 8
  POP    PC
dprint:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; n
  LD     A, [SP, 4] ; n
  CMP    A, 0
  JGE    .L208
  MOV.B  A, '-'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 4] ; n
  NEG    A, A
  ST     [SP, 4], A ; n
.L208:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 4] ; n
  CALL   uprint
  ADD    SP, 8
  POP    PC
xprint:
  PUSH   LR
  SUB    SP, 9
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; n
  ST.B   [SP, 8], C ; uplo
  LD     A, [SP, 4] ; n
  SHR    A, 4
  CMP    A, 0
  JEQ    .L209
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 4] ; n
  SHR    B, 4
  LD.B   C, [SP, 8] ; uplo
  CALL   xprint
.L209:
  LD     A, [SP, 4] ; n
  AND    A, 15
  CMP    A, 9
  JLS    .L211
  LD     A, [SP, 4] ; n
  AND    A, 15
  SUB    A, 10
  LD.B   B, [SP, 8] ; uplo
  ADD    A, B
  LD     B, [SP, 0] ; stream
  CALL   fputc
  JMP    .L210
.L211:
  LD     A, [SP, 4] ; n
  AND    A, 15
  ADD    A, '0'
  LD     B, [SP, 0] ; stream
  CALL   fputc
.L210:
  ADD    SP, 9
  POP    PC
fprint:
  PUSH   LR
  SUB    SP, 17
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; f
  ST.B   [SP, 8], C ; prec
  LD     A, [SP, 4] ; f
  LDI    B, 0 ; 0.0
  CMPF   A, B
  JGE    .L212
  MOV.B  A, '-'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 4] ; f
  NEGF   A, A
  ST     [SP, 4], A ; f
.L212:
  LD     A, [SP, 4] ; f
  FTI    A, A
  ST     [SP, 9], A ; left
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 9] ; left
  CALL   uprint
  LD.B   A, [SP, 8] ; prec
  CMP    A, 0
  JLE    .L213
  MOV.B  A, '.'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 4] ; f
  LD     B, [SP, 9] ; left
  ITF    B, B
  SUBF   A, B
  ST     [SP, 13], A ; right
.L214:
  LD     A, [SP, 13] ; right
  LDI    B, 1092616192 ; 10.0
  MULF   A, B
  ST     [SP, 13], A ; right
  FTI    A, A
  ADD    A, '0'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 13] ; right
  FTI    B, A
  ITF    B, B
  SUBF   A, B
  ST     [SP, 13], A ; right
  LD.B   A, [SP, 8] ; prec
  SUB.B  A, 1
  ST.B   [SP, 8], A ; prec
  CMP    A, 0
  JGT    .L214
.L215:
.L213:
  ADD    SP, 17
  POP    PC
eprint:
  PUSH   LR
  SUB    SP, 13
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; f
  ST.B   [SP, 8], C ; prec
  LD     A, [SP, 4] ; f
  ITF    B, 0
  CMPF   A, B
  JGE    .L216
  MOV.B  A, '-'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 4] ; f
  NEGF   A, A
  ST     [SP, 4], A ; f
.L216:
  MOV    A, 0
  ST     [SP, 9], A ; exp
  LD     A, [SP, 4] ; f
  CMPF   A, 0
  JEQ    .L217
.L218:
  LD     A, [SP, 4] ; f
  LDI    B, 1092616192 ; 10.0
  CMPF   A, B
  JLT    .L219
  LD     A, [SP, 9] ; exp
  ADD    A, 1
  ST     [SP, 9], A ; exp
  LD     A, [SP, 4] ; f
  LDI    B, 1092616192 ; 10.0
  DIVF   A, B
  ST     [SP, 4], A ; f
  JMP    .L218
.L219:
.L220:
  LD     A, [SP, 4] ; f
  LDI    B, 1065353216 ; 1.0
  CMPF   A, B
  JGE    .L221
  LD     A, [SP, 9] ; exp
  SUB    A, 1
  ST     [SP, 9], A ; exp
  LD     A, [SP, 4] ; f
  LDI    B, 1092616192 ; 10.0
  MULF   A, B
  ST     [SP, 4], A ; f
  JMP    .L220
.L221:
.L217:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 4] ; f
  LD.B   C, [SP, 8] ; prec
  CALL   fprint
  MOV.B  A, 'e'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 9] ; exp
  CALL   dprint
  ADD    SP, 13
  POP    PC
vfprintf:
  PUSH   LR
  SUB    SP, 21
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; format
  ST     [SP, 8], C ; ap
  MOV    A, 0
  ST     [SP, 16], A ; n
  LD     A, [SP, 4] ; format
  ST     [SP, 12], A ; c
.L223:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, 0
  JEQ    .L225
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, '%'
  JNE    .L227
  LD     A, [SP, 12] ; c
  ADD    A, 1
  ST     [SP, 12], A ; c
  MOV    A, 0
  ST.B   [SP, 20], A ; precision
  MOV.B  A, '0'
  LD     B, [SP, 12] ; c
  LD.B   B, [B]
  CMP.B  A, B
  JGT    .L228
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, '9'
  JGT    .L228
  LD     A, [SP, 12] ; c
  ADD    B, A, 1
  ST     [SP, 12], B ; c
  LD.B   A, [A]
  SUB.B  A, '0'
  ST.B   [SP, 20], A ; precision
.L228:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, 'u'
  JEQ    .L231
  CMP.B  A, 'd'
  JEQ    .L232
  CMP.B  A, 'i'
  JEQ    .L233
  CMP.B  A, 'x'
  JEQ    .L234
  CMP.B  A, 'X'
  JEQ    .L235
  CMP.B  A, 'f'
  JEQ    .L236
  CMP.B  A, 'e'
  JEQ    .L237
  CMP.B  A, 's'
  JEQ    .L238
  CMP.B  A, 'c'
  JEQ    .L239
  CMP.B  A, 'o'
  JEQ    .L240
  CMP.B  A, 'n'
  JEQ    .L241
  JMP    .L242
.L231:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  CALL   uprint
  JMP    .L230
.L232:
.L233:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  CALL   dprint
  JMP    .L230
.L234:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  MOV.B  C, 'a'
  CALL   xprint
  JMP    .L230
.L235:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  MOV.B  C, 'A'
  CALL   xprint
  JMP    .L230
.L236:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  LD.B   C, [SP, 20] ; precision
  CALL   fprint
  JMP    .L230
.L237:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  LD.B   C, [SP, 20] ; precision
  CALL   eprint
  JMP    .L230
.L238:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  CALL   fprintf
  JMP    .L230
.L239:
  LD     A, [SP, 8] ; ap
  ADD    B, A, 4
  ST     [SP, 8], B ; ap
  LD.B   A, [A]
  LD     B, [SP, 0] ; stream
  CALL   fputc
  JMP    .L230
.L240:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  CALL   oprint
  JMP    .L230
.L241:
  LD     A, [SP, 16] ; n
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  ST     [B], A
  JMP    .L230
.L242:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  LD     B, [SP, 0] ; stream
  CALL   fputc
.L230:
  JMP    .L226
.L227:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  LD     B, [SP, 0] ; stream
  CALL   fputc
.L226:
.L224:
  LD     A, [SP, 12] ; c
  ADD    A, 1
  ST     [SP, 12], A ; c
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
  JMP    .L223
.L225:
  MOV    A, 0
.L222:
  ADD    SP, 21
  POP    PC
vprintf:
  PUSH   C, LR
  SUB    SP, 8
  ST     [SP, 0], A ; format
  ST     [SP, 4], B ; ap
  LDI    A, =stdout
  LD     A, [A]
  LD     B, [SP, 0] ; format
  LD     C, [SP, 4] ; ap
  CALL   vfprintf
.L243:
  ADD    SP, 8
  POP    C, PC
vsnprintf:
  PUSH   LR
  SUB    SP, 36
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  ST     [SP, 8], C ; format
  ST     [SP, 12], D ; ap
  ADD    A, SP, 20 ; fake
  LD     B, [SP, 0] ; s
  ST     [A, 0], B
  MOV    B, 0
  ST     [A, 4], B
  MOV    B, 0
  ST     [A, 8], B
  LD     B, [SP, 4] ; n
  ST     [A, 12], B
  ADD    A, SP, 20 ; fake
  LD     B, [SP, 8] ; format
  LD     C, [SP, 12] ; ap
  CALL   vfprintf
  ST     [SP, 16], A ; ret
  MOV.B  A, '\0'
  ADD    B, SP, 20 ; fake
  CALL   fputc
  LD     A, [SP, 16] ; ret
.L244:
  ADD    SP, 36
  POP    PC
fprintf:
  PUSH   A, B, C, D
  PUSH   C, LR
  SUB    SP, 16
  ADD    A, SP, 32 ; format
  ST     [SP, 12], A ; ap
  LD     A, [SP, 24] ; stream
  LD     B, [SP, 28] ; format
  LD     C, [SP, 12] ; ap
  CALL   vfprintf
  ST     [SP, 8], A ; ret
  MOV    A, 0
  ST     [SP, 12], A ; ap
  LD     A, [SP, 8] ; ret
.L245:
  ADD    SP, 16
  POP    C, LR
  ADD    SP, 16
  RET
printf:
  PUSH   A, B, C, D
  PUSH   B, LR
  SUB    SP, 12
  ADD    A, SP, 24 ; format
  ST     [SP, 8], A ; ap
  LD     A, [SP, 20] ; format
  LD     B, [SP, 8] ; ap
  CALL   vprintf
  ST     [SP, 4], A ; ret
  MOV    A, 0
  ST     [SP, 8], A ; ap
  LD     A, [SP, 4] ; ret
.L246:
  ADD    SP, 12
  POP    B, LR
  ADD    SP, 16
  RET
snprintf:
  PUSH   A, B, C, D
  PUSH   D, LR
  SUB    SP, 20
  ADD    A, SP, 40 ; format
  ST     [SP, 16], A ; ap
  LD     A, [SP, 28] ; s
  LD     B, [SP, 32] ; n
  LD     C, [SP, 36] ; format
  LD     D, [SP, 16] ; ap
  CALL   vsnprintf
  ST     [SP, 12], A ; ret
  MOV    A, 0
  ST     [SP, 16], A ; ap
  LD     A, [SP, 12] ; ret
.L247:
  ADD    SP, 20
  POP    D, LR
  ADD    SP, 16
  RET
div:
  PUSH   C
  SUB    SP, 16
  ST     [SP, 0], A ; num
  ST     [SP, 4], B ; den
  ADD    A, SP, 8 ; ans
  LD     B, [SP, 0] ; num
  LD     C, [SP, 4] ; den
  DIV    B, C
  ST     [A, 0], B
  LD     B, [SP, 0] ; num
  LD     C, [SP, 4] ; den
  MOD    B, C
  ST     [A, 4], B
  ADD    A, SP, 8 ; ans
.L248:
  ADD    SP, 16
  POP    C
  RET
abs:
  SUB    SP, 4
  ST     [SP, 0], A ; n
  CMP    A, 0
  JGE    .L250
  LD     A, [SP, 0] ; n
  NEG    A, A
  JMP    .L249
.L250:
  LD     A, [SP, 0] ; n
.L249:
  ADD    SP, 4
  RET
bsearch:
  PUSH   LR
  SUB    SP, 32
  ST     [SP, 0], A ; x
  ST     [SP, 4], B ; v
  ST     [SP, 8], C ; size
  ST     [SP, 12], D ; n
  MOV    A, 0
  ST     [SP, 16], A ; low
  LD     A, [SP, 12] ; n
  SUB    A, 1
  ST     [SP, 24], A ; high
.L252:
  LD     A, [SP, 16] ; low
  LD     B, [SP, 24] ; high
  CMP    A, B
  JGT    .L253
  LD     A, [SP, 16] ; low
  LD     B, [SP, 24] ; high
  SUB    B, A
  SHR    B, 1
  ADD    A, B
  ST     [SP, 20], A ; mid
  LD     A, [SP, 0] ; x
  LD     B, [SP, 4] ; v
  LD     C, [SP, 20] ; mid
  LD     D, [SP, 8] ; size
  MUL    C, D
  ADD    B, C
  LD     C, [SP, 36] ; cmp
  CALL   C
  ST     [SP, 28], A ; cond
  CMP    A, 0
  JGE    .L255
  LD     A, [SP, 20] ; mid
  SUB    A, 1
  ST     [SP, 24], A ; high
  JMP    .L254
.L255:
  LD     A, [SP, 28] ; cond
  CMP    A, 0
  JLE    .L256
  LD     A, [SP, 20] ; mid
  ADD    A, 1
  ST     [SP, 16], A ; low
  JMP    .L254
.L256:
  LD     A, [SP, 20] ; mid
  LD     B, [SP, 8] ; size
  MUL    A, B
  JMP    .L251
.L254:
  JMP    .L252
.L253:
  MOV    A, -1
.L251:
  ADD    SP, 32
  POP    LR
  ADD    SP, 4
  RET
swap:
  PUSH   E, F
  SUB    SP, 30
  ST     [SP, 0], A ; v
  ST     [SP, 4], B ; size
  ST     [SP, 8], C ; i
  ST     [SP, 12], D ; j
  LD     A, [SP, 4] ; size
  SHR    A, 2
  ST     [SP, 16], A ; words
  LD     A, [SP, 4] ; size
  AND    A, 3
  ST.B   [SP, 20], A ; tail
  MOV    A, 0
  ST     [SP, 25], A ; k
.L257:
  LD     A, [SP, 25] ; k
  LD     B, [SP, 16] ; words
  CMP    A, B
  JCS    .L259
  LD     A, [SP, 0] ; v
  LD     B, [SP, 8] ; i
  LD     C, [SP, 4] ; size
  MUL    B, C
  ADD    A, B
  LD     B, [SP, 25] ; k
  ADD    A, B
  LD     A, [A]
  ST     [SP, 21], A ; t
  LD     A, [SP, 0] ; v
  LD     C, [SP, 12] ; j
  LD     B, [SP, 4] ; size
  MUL    C, B
  ADD    D, A, C
  LD     C, [SP, 25] ; k
  ADD    D, C
  LD     D, [D]
  LD     E, [SP, 8] ; i
  MUL    B, E, B
  ADD    A, B
  ADD    A, C
  ST     [A], D
  LD     A, [SP, 21] ; t
  LD     B, [SP, 0] ; v
  LD     C, [SP, 12] ; j
  LD     D, [SP, 4] ; size
  MUL    C, D
  ADD    B, C
  LD     C, [SP, 25] ; k
  ADD    B, C
  ST     [B], A
.L258:
  LD     A, [SP, 25] ; k
  ADD    A, 4
  ST     [SP, 25], A ; k
  JMP    .L257
.L259:
  MOV    A, 0
  ST.B   [SP, 29], A ; c
.L260:
  LD.B   A, [SP, 29] ; c
  LD.B   B, [SP, 20] ; tail
  CMP.B  A, B
  JGE    .L262
  LD     A, [SP, 0] ; v
  LD     B, [SP, 8] ; i
  LD     C, [SP, 4] ; size
  MUL    B, C
  ADD    A, B
  LD     B, [SP, 25] ; k
  ADD    A, B
  LD.B   B, [SP, 29] ; c
  ADD    A, B
  LD.B   A, [A]
  ST     [SP, 21], A ; t
  LD     A, [SP, 0] ; v
  LD     C, [SP, 12] ; j
  LD     B, [SP, 4] ; size
  MUL    C, B
  ADD    D, A, C
  LD     C, [SP, 25] ; k
  ADD    E, D, C
  LD.B   D, [SP, 29] ; c
  ADD    E, D
  LD.B   E, [E]
  LD     F, [SP, 8] ; i
  MUL    B, F, B
  ADD    A, B
  ADD    A, C
  ADD    A, D
  ST.B   [A], E
  LD     A, [SP, 21] ; t
  LD     B, [SP, 0] ; v
  LD     C, [SP, 12] ; j
  LD     D, [SP, 4] ; size
  MUL    C, D
  ADD    B, C
  LD     C, [SP, 25] ; k
  ADD    B, C
  LD.B   C, [SP, 29] ; c
  ADD    B, C
  ST.B   [B], A
.L261:
  LD.B   A, [SP, 29] ; c
  ADD.B  A, 1
  ST.B   [SP, 29], A ; c
  JMP    .L260
.L262:
  ADD    SP, 30
  POP    E, F
  RET
qsort:
  PUSH   E, LR
  SUB    SP, 24
  ST     [SP, 0], A ; v
  ST     [SP, 4], B ; size
  ST     [SP, 8], C ; left
  ST     [SP, 12], D ; right
  LD     A, [SP, 8] ; left
  LD     B, [SP, 12] ; right
  CMP    A, B
  JLT    .L264
  JMP    .L263
.L264:
  LD     A, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 8] ; left
  LD     D, [SP, 12] ; right
  SUB    D, C
  SHR    D, 1
  ADD    D, C, D
  CALL   swap
  LD     A, [SP, 8] ; left
  ST     [SP, 20], A ; last
  LD     A, [SP, 8] ; left
  ADD    A, 1
  ST     [SP, 16], A ; i
.L265:
  LD     A, [SP, 16] ; i
  LD     B, [SP, 12] ; right
  CMP    A, B
  JGT    .L267
  LD     B, [SP, 0] ; v
  LD     A, [SP, 16] ; i
  LD     C, [SP, 4] ; size
  MUL    A, C
  ADD    A, B, A
  LD     D, [SP, 8] ; left
  MUL    C, D, C
  ADD    B, C
  LD     C, [SP, 32] ; cmp
  CALL   C
  CMP    A, 0
  JGE    .L268
  LD     A, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 20] ; last
  ADD    C, 1
  ST     [SP, 20], C ; last
  LD     D, [SP, 16] ; i
  CALL   swap
.L268:
.L266:
  LD     A, [SP, 16] ; i
  ADD    A, 1
  ST     [SP, 16], A ; i
  JMP    .L265
.L267:
  LD     A, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 8] ; left
  LD     D, [SP, 20] ; last
  CALL   swap
  LD     A, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 8] ; left
  LD     D, [SP, 20] ; last
  SUB    D, 1
  LD     E, [SP, 32] ; cmp
  PUSH   E
  CALL   qsort
  LD     A, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 20] ; last
  ADD    C, 1
  LD     D, [SP, 12] ; right
  LD     E, [SP, 32] ; cmp
  PUSH   E
  CALL   qsort
.L263:
  ADD    SP, 24
  POP    E, LR
  ADD    SP, 4
  RET
rand:
  PUSH   B, C
  LDI    B, 1103515245
  LDI    A, =next_rand
  LD     C, [A]
  MUL    B, C
  LDI    C, 12345
  ADD    B, C
  ST     [A], B
  LDI    A, =next_rand
  LD     A, [A]
.L269:
  POP    B, C
  RET
srand:
  PUSH   B
  SUB    SP, 4
  ST     [SP, 0], A ; seed
  LDI    B, =next_rand
  ST     [B], A
  ADD    SP, 4
  POP    B
  RET
atoi:
  PUSH   B, C
  SUB    SP, 12
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 8], A ; n
  MOV    A, 0
  ST     [SP, 4], A ; i
.L271:
  MOV.B  A, '0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 4] ; i
  LD.B   B, [B, C]
  CMP.B  A, B
  JGT    .L273
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  CMP.B  A, '9'
  JGT    .L273
  MOV    A, 10
  LD     B, [SP, 8] ; n
  MUL    A, B
  LD     B, [SP, 0] ; s
  LD     C, [SP, 4] ; i
  LD.B   B, [B, C]
  SUB.B  B, '0'
  ADD    A, B
  ST     [SP, 8], A ; n
.L272:
  LD     A, [SP, 4] ; i
  ADD    A, 1
  ST     [SP, 4], A ; i
  JMP    .L271
.L273:
  LD     A, [SP, 8] ; n
.L270:
  ADD    SP, 12
  POP    B, C
  RET
atof:
  PUSH   B, C
  SUB    SP, 20
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 12], A ; i
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '-'
  JNE    .L276
  MOV    A, -1
  JMP    .L275
.L276:
  MOV    A, 1
.L275:
  ST     [SP, 16], A ; sign
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '+'
  JEQ    .L278
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '-'
  JNE    .L277
.L278:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
.L277:
  LDI    A, 0 ; 0.0
  ST     [SP, 4], A ; val
.L279:
  MOV.B  A, '0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  LD.B   B, [B, C]
  CMP.B  A, B
  JGT    .L281
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '9'
  JGT    .L281
  LDI    A, 1092616192 ; 10.0
  LD     B, [SP, 4] ; val
  MULF   A, B
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  LD.B   B, [B, C]
  SUB.B  B, '0'
  ITF    B, B
  ADDF   A, B
  ST     [SP, 4], A ; val
.L280:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L279
.L281:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '.'
  JNE    .L282
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
.L282:
  LDI    A, 1065353216 ; 1.0
  ST     [SP, 8], A ; pow
.L283:
  MOV.B  A, '0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  LD.B   B, [B, C]
  CMP.B  A, B
  JGT    .L285
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '9'
  JGT    .L285
  LDI    A, 1092616192 ; 10.0
  LD     B, [SP, 4] ; val
  MULF   A, B
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  LD.B   B, [B, C]
  SUB.B  B, '0'
  ITF    B, B
  ADDF   A, B
  ST     [SP, 4], A ; val
  LD     A, [SP, 8] ; pow
  LDI    B, 1092616192 ; 10.0
  MULF   A, B
  ST     [SP, 8], A ; pow
.L284:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L283
.L285:
  LD     A, [SP, 16] ; sign
  ITF    A, A
  LD     B, [SP, 4] ; val
  MULF   A, B
  LD     B, [SP, 8] ; pow
  DIVF   A, B
.L274:
  ADD    SP, 20
  POP    B, C
  RET
morecore:
  PUSH   B, LR
  SUB    SP, 12
  ST     [SP, 0], A ; n
  CALL   getheap
  ST     [SP, 4], A ; core
  ST     [SP, 8], A ; header
  LD     A, [SP, 0] ; n
  LD     B, [SP, 8] ; header
  ST     [B, 4], A ; .size
  LD     A, [SP, 8] ; header
  ADD    A, 8
  CALL   free
  LDI    A, =freehead
  LD     A, [A]
.L286:
  ADD    SP, 12
  POP    B, PC
malloc:
  PUSH   B, C, LR
  SUB    SP, 16
  ST     [SP, 0], A ; bytes
  MOV    A, 8
  LD     B, [SP, 0] ; bytes
  ADD    A, B
  ST     [SP, 12], A ; units
  LDI    A, =freehead
  LD     A, [A]
  ST     [SP, 8], A ; prevp
  CMP    A, 0
  JNE    .L288
  LDI    A, =base
  ST     [SP, 8], A ; prevp
  LDI    B, =freehead
  ST     [B], A
  LDI    B, =base
  ST     [B, 0], A ; .next
  MOV    A, 0
  LDI    B, =base
  ST     [B, 4], A ; .size
.L288:
  LD     A, [SP, 8] ; prevp
  LD     A, [A, 0] ; .next
  ST     [SP, 4], A ; p
.L289:
  LD     A, [SP, 4] ; p
  LD     A, [A, 4] ; .size
  LD     B, [SP, 12] ; units
  CMP    A, B
  JCC    .L292
  LD     A, [SP, 4] ; p
  LD     A, [A, 4] ; .size
  LD     B, [SP, 12] ; units
  CMP    A, B
  JNE    .L294
  LD     A, [SP, 4] ; p
  LD     A, [A, 0] ; .next
  LD     B, [SP, 8] ; prevp
  ST     [B, 0], A ; .next
  JMP    .L293
.L294:
  LD     A, [SP, 4] ; p
  LD     B, [A, 4] ; .size
  LD     C, [SP, 12] ; units
  SUB    B, C
  ST     [A, 4], B ; .size
  LD     A, [SP, 4] ; p
  LD     B, [A, 4] ; .size
  ADD    A, B
  ST     [SP, 4], A ; p
  LD     A, [SP, 12] ; units
  LD     B, [SP, 4] ; p
  ST     [B, 4], A ; .size
.L293:
  LD     A, [SP, 8] ; prevp
  LDI    B, =freehead
  ST     [B], A
  LD     A, [SP, 4] ; p
  ADD    A, 8
  JMP    .L287
.L292:
  LD     A, [SP, 4] ; p
  LDI    B, =freehead
  LD     B, [B]
  CMP    A, B
  JNE    .L295
  LD     A, [SP, 12] ; units
  CALL   morecore
  ST     [SP, 4], A ; p
  CMP    A, 0
  JNE    .L296
  MOV    A, 0
  JMP    .L287
.L296:
.L295:
.L290:
  LD     A, [SP, 4] ; p
  ST     [SP, 8], A ; prevp
  LD     A, [SP, 4] ; p
  LD     A, [A, 0] ; .next
  ST     [SP, 4], A ; p
  JMP    .L289
.L291:
.L287:
  ADD    SP, 16
  POP    B, C, PC
free:
  PUSH   B, C
  SUB    SP, 12
  ST     [SP, 0], A ; original
  CMP    A, 0
  JEQ    .L297
  LD     A, [SP, 0] ; original
  SUB    A, 8
  ST     [SP, 4], A ; free
  LDI    A, =freehead
  LD     A, [A]
  ST     [SP, 8], A ; p
.L298:
  LD     A, [SP, 8] ; p
  LD     B, [SP, 4] ; free
  CMP    A, B
  JCS    .L301
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  LD     B, [B, 0] ; .next
  CMP    A, B
  JCC    .L300
.L301:
  LD     A, [SP, 8] ; p
  LD     B, [A, 0] ; .next
  CMP    A, B
  JCC    .L302
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  CMP    A, B
  JHI    .L303
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  LD     B, [B, 0] ; .next
  CMP    A, B
  JCS    .L302
.L303:
  JMP    .L300
.L302:
.L299:
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  ST     [SP, 8], A ; p
  JMP    .L298
.L300:
  LD     A, [SP, 4] ; free
  LD     B, [A, 4] ; .size
  ADD    A, B
  LD     B, [SP, 8] ; p
  LD     B, [B, 0] ; .next
  CMP    A, B
  JNE    .L305
  LD     A, [SP, 4] ; free
  LD     B, [A, 4] ; .size
  LD     C, [SP, 8] ; p
  LD     C, [C, 0] ; .next
  LD     C, [C, 4] ; .size
  ADD    B, C
  ST     [A, 4], B ; .size
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  LD     A, [A, 0] ; .next
  LD     B, [SP, 4] ; free
  ST     [B, 0], A ; .next
  JMP    .L304
.L305:
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  LD     B, [SP, 4] ; free
  ST     [B, 0], A ; .next
.L304:
  LD     A, [SP, 8] ; p
  LD     B, [A, 4] ; .size
  ADD    A, B
  LD     B, [SP, 4] ; free
  CMP    A, B
  JNE    .L307
  LD     A, [SP, 8] ; p
  LD     B, [A, 4] ; .size
  LD     C, [SP, 4] ; free
  LD     C, [C, 4] ; .size
  ADD    B, C
  ST     [A, 4], B ; .size
  LD     A, [SP, 4] ; free
  LD     A, [A, 0] ; .next
  LD     B, [SP, 8] ; p
  ST     [B, 0], A ; .next
  JMP    .L306
.L307:
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  ST     [B, 0], A ; .next
.L306:
  LD     A, [SP, 8] ; p
  LDI    B, =freehead
  ST     [B], A
.L297:
  ADD    SP, 12
  POP    B, C
  RET
realloc:
  PUSH   C, LR
  SUB    SP, 12
  ST     [SP, 0], A ; p
  ST     [SP, 4], B ; size
  LD     A, [SP, 4] ; size
  CALL   malloc
  ST     [SP, 8], A ; d
  LD     B, [SP, 0] ; p
  LD     C, [SP, 4] ; size
  CALL   memcpy
  LD     A, [SP, 0] ; p
  CALL   free
  LD     A, [SP, 8] ; d
.L308:
  ADD    SP, 12
  POP    C, PC
calloc:
  PUSH   C, LR
  SUB    SP, 32
  ST     [SP, 0], A ; n
  ST     [SP, 4], B ; size
  LD     A, [SP, 0] ; n
  LD     B, [SP, 4] ; size
  MUL    A, B
  ST     [SP, 8], A ; bytes
  SHR    A, 2
  ST     [SP, 12], A ; words
  LD     A, [SP, 8] ; bytes
  AND    A, 3
  ST     [SP, 16], A ; tail
  LD     A, [SP, 8] ; bytes
  CALL   malloc
  ST     [SP, 24], A ; p
  MOV    A, 0
  ST     [SP, 20], A ; i
.L310:
  LD     A, [SP, 20] ; i
  LD     B, [SP, 12] ; words
  CMP    A, B
  JCS    .L312
  MOV    A, 0
  LD     B, [SP, 24] ; p
  LD     C, [SP, 20] ; i
  ADD    B, C
  ST     [B], A
.L311:
  LD     A, [SP, 20] ; i
  ADD    A, 1
  ST     [SP, 20], A ; i
  JMP    .L310
.L312:
  MOV    A, 0
  ST     [SP, 28], A ; c
.L313:
  LD     A, [SP, 28] ; c
  LD     B, [SP, 16] ; tail
  CMP    A, B
  JCS    .L315
  MOV    A, 0
  LD     B, [SP, 24] ; p
  LD     C, [SP, 20] ; i
  ADD    B, C
  LD     C, [SP, 28] ; c
  ADD    B, C
  ST.B   [B], A
.L314:
  LD     A, [SP, 28] ; c
  ADD    A, 1
  ST     [SP, 28], A ; c
  JMP    .L313
.L315:
  LD     A, [SP, 24] ; p
.L309:
  ADD    SP, 32
  POP    C, PC
strlen:
  PUSH   B
  SUB    SP, 8
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 4], A ; l
.L317:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; l
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JEQ    .L318
  LD     A, [SP, 4] ; l
  ADD    A, 1
  ST     [SP, 4], A ; l
  JMP    .L317
.L318:
  LD     A, [SP, 4] ; l
.L316:
  ADD    SP, 8
  POP    B
  RET
strcpy:
  PUSH   C
  SUB    SP, 12
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  MOV    A, 0
  ST     [SP, 8], A ; i
.L320:
  LD     B, [SP, 4] ; t
  LD     A, [SP, 8] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 0] ; s
  ST.B   [C, A], B
  CMP.B  B, '\0'
  JEQ    .L322
.L321:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
  JMP    .L320
.L322:
  LD     A, [SP, 0] ; s
.L319:
  ADD    SP, 12
  POP    C
  RET
strncpy:
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  MOV    A, 0
  ST     [SP, 12], A ; i
.L324:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L326
  LD     B, [SP, 4] ; t
  LD     A, [SP, 12] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 0] ; s
  ST.B   [C, A], B
  CMP.B  B, '\0'
  JEQ    .L326
.L325:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L324
.L326:
  LD     A, [SP, 0] ; s
.L323:
  ADD    SP, 16
  RET
strdup:
  PUSH   B, C, D, LR
  SUB    SP, 8
  ST     [SP, 0], A ; s
  CALL   strlen
  ADD    A, 1
  CALL   malloc
  ST     [SP, 4], A ; p
  CMP    A, 0
  JEQ    .L328
  LD     D, [SP, 4] ; p
  LD     B, [SP, 0] ; s
  MOV    A, B
  CALL   strlen
  ADD    C, A, 1
  MOV    A, D
  CALL   strncpy
.L328:
  LD     A, [SP, 4] ; p
.L327:
  ADD    SP, 8
  POP    B, C, D, PC
strndup:
  PUSH   C, LR
  SUB    SP, 12
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  LD     A, [SP, 4] ; n
  CALL   malloc
  ST     [SP, 8], A ; p
  CMP    A, 0
  JEQ    .L330
  LD     A, [SP, 8] ; p
  LD     B, [SP, 0] ; s
  LD     C, [SP, 4] ; n
  CALL   strncpy
.L330:
  LD     A, [SP, 8] ; p
.L329:
  ADD    SP, 12
  POP    C, PC
strcat:
  PUSH   C, D, LR
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  LD     A, [SP, 0] ; s
  CALL   strlen
  ST     [SP, 8], A ; i
  MOV    A, 0
  ST     [SP, 12], A ; j
.L332:
  LD     A, [SP, 4] ; t
  LD     B, [SP, 12] ; j
  ADD    C, B, 1
  ST     [SP, 12], C ; j
  LD.B   A, [A, B]
  LD     B, [SP, 0] ; s
  LD     C, [SP, 8] ; i
  ADD    D, C, 1
  ST     [SP, 8], D ; i
  ST.B   [B, C], A
  CMP.B  A, '\0'
  JEQ    .L333
  JMP    .L332
.L333:
  LD     A, [SP, 0] ; s
.L331:
  ADD    SP, 16
  POP    C, D, PC
strncat:
  PUSH   D, LR
  SUB    SP, 20
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  LD     A, [SP, 0] ; s
  CALL   strlen
  ST     [SP, 12], A ; i
  MOV    A, 0
  ST     [SP, 16], A ; j
.L335:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L336
  LD     A, [SP, 4] ; t
  LD     B, [SP, 16] ; j
  ADD    C, B, 1
  ST     [SP, 16], C ; j
  LD.B   A, [A, B]
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ADD    D, C, 1
  ST     [SP, 12], D ; i
  ST.B   [B, C], A
  CMP.B  A, '\0'
  JEQ    .L336
  JMP    .L335
.L336:
  LD     A, [SP, 0] ; s
.L334:
  ADD    SP, 20
  POP    D, PC
strrev:
  PUSH   B, C, LR
  SUB    SP, 13
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 4], A ; front
  LD     A, [SP, 0] ; s
  CALL   strlen
  SUB    A, 1
  ST     [SP, 8], A ; back
.L338:
  LD     A, [SP, 4] ; front
  LD     B, [SP, 8] ; back
  CMP    A, B
  JCS    .L340
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; front
  LD.B   A, [A, B]
  ST.B   [SP, 12], A ; temp
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; back
  LD.B   B, [A, B]
  LD     C, [SP, 4] ; front
  ST.B   [A, C], B
  LD.B   A, [SP, 12] ; temp
  LD     B, [SP, 0] ; s
  LD     C, [SP, 8] ; back
  ST.B   [B, C], A
.L339:
  LD     A, [SP, 4] ; front
  ADD    A, 1
  ST     [SP, 4], A ; front
  LD     A, [SP, 8] ; back
  SUB    A, 1
  ST     [SP, 8], A ; back
  JMP    .L338
.L340:
  LD     A, [SP, 0] ; s
.L337:
  ADD    SP, 13
  POP    B, C, PC
strcmp:
  PUSH   C
  SUB    SP, 12
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  MOV    A, 0
  ST     [SP, 8], A ; i
.L342:
  LD     B, [SP, 0] ; s
  LD     A, [SP, 8] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 4] ; t
  LD.B   A, [C, A]
  CMP.B  B, A
  JNE    .L344
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JNE    .L345
  MOV    A, 0
  JMP    .L341
.L345:
.L343:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
  JMP    .L342
.L344:
  LD     B, [SP, 0] ; s
  LD     A, [SP, 8] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 4] ; t
  LD.B   A, [C, A]
  SUB.B  A, B, A
.L341:
  ADD    SP, 12
  POP    C
  RET
strncmp:
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  MOV    A, 0
  ST     [SP, 12], A ; i
.L347:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L349
  LD     B, [SP, 0] ; s
  LD     A, [SP, 12] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 4] ; t
  LD.B   A, [C, A]
  CMP.B  B, A
  JNE    .L349
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JNE    .L350
  MOV    A, 0
  JMP    .L346
.L350:
.L348:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L347
.L349:
  LD     B, [SP, 0] ; s
  LD     A, [SP, 12] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 4] ; t
  LD.B   A, [C, A]
  SUB.B  A, B, A
.L346:
  ADD    SP, 16
  RET
strchr:
  SUB    SP, 9
  ST     [SP, 0], A ; s
  ST.B   [SP, 4], B ; c
  MOV    A, 0
  ST     [SP, 5], A ; i
.L352:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JEQ    .L354
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  LD.B   A, [A, B]
  LD.B   B, [SP, 4] ; c
  CMP.B  A, B
  JNE    .L355
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  ADD    A, B
  JMP    .L351
.L355:
.L353:
  LD     A, [SP, 5] ; i
  ADD    A, 1
  ST     [SP, 5], A ; i
  JMP    .L352
.L354:
  MOV    A, 0
.L351:
  ADD    SP, 9
  RET
memset:
  SUB    SP, 13
  ST     [SP, 0], A ; s
  ST.B   [SP, 4], B ; v
  ST     [SP, 5], C ; n
  MOV    A, 0
  ST     [SP, 9], A ; i
.L357:
  LD     A, [SP, 9] ; i
  LD     B, [SP, 5] ; n
  CMP    A, B
  JCS    .L359
  LD.B   A, [SP, 4] ; v
  LD     B, [SP, 0] ; s
  LD     C, [SP, 9] ; i
  ADD    B, C
  ST.B   [B], A
.L358:
  LD     A, [SP, 9] ; i
  ADD    A, 1
  ST     [SP, 9], A ; i
  JMP    .L357
.L359:
  LD     A, [SP, 0] ; s
.L356:
  ADD    SP, 13
  RET
memcpy:
  PUSH   D
  SUB    SP, 22
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  LD     A, [SP, 8] ; n
  SHR    A, 2
  ST     [SP, 12], A ; words
  LD     A, [SP, 8] ; n
  AND    A, 3
  ST.B   [SP, 16], A ; tail
  MOV    A, 0
  ST     [SP, 17], A ; i
.L361:
  LD     A, [SP, 17] ; i
  LD     B, [SP, 12] ; words
  CMP    A, B
  JCS    .L363
  LD     B, [SP, 4] ; t
  LD     A, [SP, 17] ; i
  SHL    A, 2
  ADD    B, A
  LD     B, [B]
  LD     C, [SP, 0] ; s
  ADD    A, C, A
  ST     [A], B
.L362:
  LD     A, [SP, 17] ; i
  ADD    A, 1
  ST     [SP, 17], A ; i
  JMP    .L361
.L363:
  MOV    A, 0
  ST.B   [SP, 21], A ; c
.L364:
  LD.B   A, [SP, 21] ; c
  LD.B   B, [SP, 16] ; tail
  CMP.B  A, B
  JGE    .L366
  LD     B, [SP, 4] ; t
  LD     A, [SP, 17] ; i
  ADD    C, B, A
  LD.B   B, [SP, 21] ; c
  ADD    C, B
  LD.B   C, [C]
  LD     D, [SP, 0] ; s
  ADD    A, D, A
  ADD    A, B
  ST.B   [A], C
.L365:
  LD.B   A, [SP, 21] ; c
  ADD.B  A, 1
  ST.B   [SP, 21], A ; c
  JMP    .L364
.L366:
  LD     A, [SP, 0] ; s
.L360:
  ADD    SP, 22
  POP    D
  RET
memcmp:
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  MOV    A, 0
  ST     [SP, 12], A ; i
.L368:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L370
  LD     B, [SP, 0] ; s
  LD     A, [SP, 12] ; i
  ADD    B, A
  LD.B   B, [B]
  LD     C, [SP, 4] ; t
  ADD    A, C, A
  LD.B   A, [A]
  CMP.B  B, A
  JEQ    .L371
  LD     B, [SP, 0] ; s
  LD     A, [SP, 12] ; i
  ADD    B, A
  LD.B   B, [B]
  LD     C, [SP, 4] ; t
  ADD    A, C, A
  LD.B   A, [A]
  SUB.B  A, B, A
  JMP    .L367
.L371:
.L369:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L368
.L370:
  MOV    A, 0
.L367:
  ADD    SP, 16
  RET