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
errno: .word 0
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
  ADD    B, B, E ; 
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
  ADD    B, B, E ; 
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
  SUB.B  A, '*'
  CMP.B  A, 5
  JHI    .L59
  LDI    B, =.L54
  SHL    A, 2
  LD     PC, [B, A]
.L56:
  LDI    B, =add_
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 0], B ; .op
  JMP    .L53
.L57:
  LDI    B, =sub_
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 0], B ; .op
  JMP    .L53
.L55:
  LDI    B, =mul_
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 0], B ; .op
  JMP    .L53
.L58:
  LDI    B, =div_
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 0], B ; .op
.L59:
.L53:
  LD     B, [SP, 4] ; left
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 4], B ; .left
  LD     B, [SP, 8] ; right
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 8], B ; .right
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
  MOV    B, 0
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 0], B ; .op
  LD     B, [SP, 4] ; left
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 4], B ; .left
  LD     B, [SP, 8] ; right
  LD     A, [SP, 12] ; node
  LD     A, [A, 5] ; .binary
  ST     [A, 8], B ; .right
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
  SUB.B  A, 0
  CMP.B  A, 3
  JHI    .L74
  LDI    B, =.L69
  SHL    A, 2
  LD     PC, [B, A]
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
  LDI    B, =current
  LD     A, [B]
  LD     A, [A, 7] ; .next
  ST     [B], A
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
  LDI    C, =TokenTypeMap
  LD.B   B, [SP, 0] ; token
  SHL    B, 2
  LD     B, [C, B]
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
  LD.B   C, [A]
  MOV    A, 31
  LD     B, [SP, 4] ; hash
  MUL    A, B
  ADD    A, C, A
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
  MOV    B, 2
  LD     A, [SP, 0] ; old
  LD     A, [A, 8] ; .capacity
  MUL    A, B, A
  CALL   _allocIntMap
  ST     [SP, 4], A ; map
  MOV    A, 0
  ST     [SP, 8], A ; i
.L123:
  LD     B, [SP, 8] ; i
  LD     A, [SP, 0] ; old
  LD     A, [A, 8] ; .capacity
  CMP    B, A
  JGE    .L125
  LD     A, [SP, 4] ; map
  LD     B, [SP, 0] ; old
  LD     C, [B, 0] ; .data
  LD     B, [SP, 8] ; i
  SHL    B, 2
  LD     B, [C, B]
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
  LD     A, [SP, 0] ; map
  LD     B, [A, 4] ; .size
  LD     A, [A, 8] ; .capacity
  CMP    B, A
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
  LD     B, [A, 0] ; .data
  LD     A, [SP, 16] ; h
  SHL    A, 2
  LD     A, [B, A]
  CMP    A, 0
  JNE    .L130
  MOV    A, 0
  LD     B, [SP, 12] ; pair
  ST     [B, 8], A ; .next
  LD     C, [SP, 12] ; pair
  LD     A, [SP, 0] ; map
  LD     B, [A, 0] ; .data
  LD     A, [SP, 16] ; h
  SHL    A, 2
  ST     [B, A], C
  JMP    .L129
.L130:
  LD     A, [SP, 0] ; map
  LD     B, [A, 0] ; .data
  LD     A, [SP, 16] ; h
  SHL    A, 2
  LD     A, [B, A]
  LD     A, [A, 8] ; .next
  LD     B, [SP, 12] ; pair
  ST     [B, 8], A ; .next
  LD     C, [SP, 12] ; pair
  LD     A, [SP, 0] ; map
  LD     B, [A, 0] ; .data
  LD     A, [SP, 16] ; h
  SHL    A, 2
  LD     A, [B, A]
  ST     [A, 8], C ; .next
.L129:
  LD     B, [SP, 0] ; map
  LD     A, [B, 4] ; .size
  ADD    A, 1
  ST     [B, 4], A ; .size
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
  LD     C, [B, 0] ; .data
  LD     B, [SP, 12] ; h
  SHL    B, 2
  LD     B, [C, B]
  LD     B, [B, 0] ; .key
  CALL   strcmp
  CMP    A, 0
  JNE    .L134
  LD     A, [SP, 0] ; map
  LD     B, [A, 0] ; .data
  LD     A, [SP, 12] ; h
  SHL    A, 2
  LD     A, [B, A]
  ST     [SP, 8], A ; pair
  LD     C, [A, 8] ; .next
  LD     A, [SP, 0] ; map
  LD     B, [A, 0] ; .data
  LD     A, [SP, 12] ; h
  SHL    A, 2
  ST     [B, A], C
  JMP    .L133
.L134:
  LD     A, [SP, 0] ; map
  LD     B, [A, 0] ; .data
  LD     A, [SP, 12] ; h
  SHL    A, 2
  LD     A, [B, A]
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
  LD     B, [SP, 0] ; map
  LD     A, [B, 4] ; .size
  SUB    A, 1
  ST     [B, 4], A ; .size
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
  LD     B, [SP, 4] ; i
  LD     A, [SP, 0] ; map
  LD     A, [A, 8] ; .capacity
  CMP    B, A
  JGE    .L144
  LD     A, [SP, 0] ; map
  LD     B, [A, 0] ; .data
  LD     A, [SP, 4] ; i
  SHL    A, 2
  LD     A, [B, A]
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
div:
  PUSH   C
  SUB    SP, 16
  ST     [SP, 0], A ; num
  ST     [SP, 4], B ; den
  ADD    C, SP, 8 ; ans
  LD     A, [SP, 0] ; num
  LD     B, [SP, 4] ; den
  DIV    A, B
  ST     [C, 0], A
  LD     A, [SP, 0] ; num
  LD     B, [SP, 4] ; den
  MOD    A, B
  ST     [C, 4], A
  ADD    A, SP, 8 ; ans
.L145:
  ADD    SP, 16
  POP    C
  RET
abs:
  SUB    SP, 4
  ST     [SP, 0], A ; n
  CMP    A, 0
  JGE    .L147
  LD     A, [SP, 0] ; n
  NEG    A, A
  JMP    .L146
.L147:
  LD     A, [SP, 0] ; n
.L146:
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
.L149:
  LD     A, [SP, 16] ; low
  LD     B, [SP, 24] ; high
  CMP    A, B
  JGT    .L150
  LD     B, [SP, 16] ; low
  LD     A, [SP, 24] ; high
  SUB    A, B
  SHR    A, 1
  ADD    A, B, A
  ST     [SP, 20], A ; mid
  LD     D, [SP, 0] ; x
  LD     C, [SP, 4] ; v
  LD     A, [SP, 20] ; mid
  LD     B, [SP, 8] ; size
  MUL    A, B
  ADD    B, C, A ; 
  MOV    A, D
  CALL   D
  ST     [SP, 28], A ; cond
  CMP    A, 0
  JGE    .L152
  LD     A, [SP, 20] ; mid
  SUB    A, 1
  ST     [SP, 24], A ; high
  JMP    .L151
.L152:
  LD     A, [SP, 28] ; cond
  CMP    A, 0
  JLE    .L153
  LD     A, [SP, 20] ; mid
  ADD    A, 1
  ST     [SP, 16], A ; low
  JMP    .L151
.L153:
  LD     A, [SP, 20] ; mid
  LD     B, [SP, 8] ; size
  MUL    A, B
  JMP    .L148
.L151:
  JMP    .L149
.L150:
  MOV    A, -1
.L148:
  ADD    SP, 32
  POP    LR
  ADD    SP, 4
  RET
swap:
  PUSH   E
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
.L154:
  LD     A, [SP, 25] ; k
  LD     B, [SP, 16] ; words
  CMP    A, B
  JCS    .L156
  LD     C, [SP, 0] ; v
  LD     A, [SP, 8] ; i
  LD     B, [SP, 4] ; size
  MUL    A, B
  ADD    A, C, A
  LD     B, [SP, 25] ; k
  ADD    A, B
  LD     A, [A]
  ST     [SP, 21], A ; t
  LD     E, [SP, 0] ; v
  LD     A, [SP, 12] ; j
  LD     C, [SP, 4] ; size
  MUL    A, C
  ADD    A, E, A
  LD     D, [SP, 25] ; k
  ADD    A, D
  LD     B, [A]
  LD     A, [SP, 8] ; i
  MUL    A, C
  ADD    A, E, A
  ADD    A, D
  ST     [A], B
  LD     D, [SP, 21] ; t
  LD     C, [SP, 0] ; v
  LD     A, [SP, 12] ; j
  LD     B, [SP, 4] ; size
  MUL    A, B
  ADD    A, C, A
  LD     B, [SP, 25] ; k
  ADD    A, B
  ST     [A], D
.L155:
  LD     A, [SP, 25] ; k
  ADD    A, 4
  ST     [SP, 25], A ; k
  JMP    .L154
.L156:
  MOV    A, 0
  ST.B   [SP, 29], A ; c
.L157:
  LD.B   A, [SP, 29] ; c
  LD.B   B, [SP, 20] ; tail
  CMP.B  A, B
  JGE    .L159
  LD     C, [SP, 0] ; v
  LD     A, [SP, 8] ; i
  LD     B, [SP, 4] ; size
  MUL    A, B
  ADD    A, C, A
  LD     B, [SP, 25] ; k
  ADD    A, B
  LD.B   B, [SP, 29] ; c
  ADD    A, B
  LD.B   A, [A]
  ST     [SP, 21], A ; t
  LD     B, [SP, 0] ; v
  LD     A, [SP, 12] ; j
  LD     C, [SP, 4] ; size
  MUL    A, C
  ADD    A, B, A
  LD     D, [SP, 25] ; k
  ADD    A, D
  LD.B   E, [SP, 29] ; c
  ADD    A, E
  LD.B   B, [A]
  LD     A, [SP, 8] ; i
  MUL    A, C
  ADD    A, B, A
  ADD    A, D
  ADD    A, E
  ST.B   [A], B
  LD     D, [SP, 21] ; t
  LD     C, [SP, 0] ; v
  LD     A, [SP, 12] ; j
  LD     B, [SP, 4] ; size
  MUL    A, B
  ADD    A, C, A
  LD     B, [SP, 25] ; k
  ADD    A, B
  LD.B   B, [SP, 29] ; c
  ADD    A, B
  ST.B   [A], D
.L158:
  LD.B   A, [SP, 29] ; c
  ADD.B  A, 1
  ST.B   [SP, 29], A ; c
  JMP    .L157
.L159:
  ADD    SP, 30
  POP    E
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
  JLT    .L161
  JMP    .L160
.L161:
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
.L162:
  LD     A, [SP, 16] ; i
  LD     B, [SP, 12] ; right
  CMP    A, B
  JGT    .L164
  LD     D, [SP, 0] ; v
  LD     A, [SP, 16] ; i
  LD     C, [SP, 4] ; size
  MUL    A, C
  ADD    A, D, A ; 
  LD     B, [SP, 8] ; left
  MUL    B, C
  ADD    B, D, B ; 
  CALL   D
  CMP    A, 0
  JGE    .L165
  LD     A, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 20] ; last
  ADD    C, 1
  ST     [SP, 20], C ; last
  LD     D, [SP, 16] ; i
  CALL   swap
.L165:
.L163:
  LD     A, [SP, 16] ; i
  ADD    A, 1
  ST     [SP, 16], A ; i
  JMP    .L162
.L164:
  LD     A, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 8] ; left
  LD     D, [SP, 20] ; last
  CALL   swap
  LD     E, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 8] ; left
  LD     A, [SP, 20] ; last
  SUB    D, A, 1
  MOV    A, E
  PUSH   E
  CALL   qsort
  LD     E, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     A, [SP, 20] ; last
  ADD    C, A, 1
  LD     D, [SP, 12] ; right
  MOV    A, E
  PUSH   E
  CALL   qsort
.L160:
  ADD    SP, 24
  POP    E, LR
  ADD    SP, 4
  RET
rand:
  PUSH   B, C
  LDI    A, 1103515245
  LDI    C, =next_rand
  LD     B, [C]
  MUL    A, B
  LDI    B, 12345
  ADD    A, B
  ST     [C], A
  LDI    A, =next_rand
  LD     A, [A]
.L166:
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
.L168:
  MOV.B  C, '0'
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  CMP.B  C, A
  JGT    .L170
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  CMP.B  A, '9'
  JGT    .L170
  MOV    A, 10
  LD     B, [SP, 8] ; n
  MUL    C, A, B
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; i
  LD.B   A, [A, B]
  SUB.B  A, '0'
  ADD    A, C, A
  ST     [SP, 8], A ; n
.L169:
  LD     A, [SP, 4] ; i
  ADD    A, 1
  ST     [SP, 4], A ; i
  JMP    .L168
.L170:
  LD     A, [SP, 8] ; n
.L167:
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
  JNE    .L173
  MOV    A, -1
  JMP    .L172
.L173:
  MOV    B, 1
.L172:
  ST     [SP, 16], A ; sign
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '+'
  JEQ    .L175
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '-'
  JNE    .L174
.L175:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
.L174:
  LDI    A, 0 ; 0.0
  ST     [SP, 4], A ; val
.L176:
  MOV.B  C, '0'
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  C, A
  JGT    .L178
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '9'
  JGT    .L178
  LDI    A, 1092616192 ; 10.0
  LD     B, [SP, 4] ; val
  MULF   C, A, B
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  SUB.B  A, '0'
  ITF    A, A
  ADDF   A, C, A
  ST     [SP, 4], A ; val
.L177:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L176
.L178:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '.'
  JNE    .L179
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
.L179:
  LDI    A, 1065353216 ; 1.0
  ST     [SP, 8], A ; pow
.L180:
  MOV.B  C, '0'
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  C, A
  JGT    .L182
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '9'
  JGT    .L182
  LDI    A, 1092616192 ; 10.0
  LD     B, [SP, 4] ; val
  MULF   C, A, B
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  SUB.B  A, '0'
  ITF    A, A
  ADDF   A, C, A
  ST     [SP, 4], A ; val
  LD     A, [SP, 8] ; pow
  LDI    B, 1092616192 ; 10.0
  MULF   A, B
  ST     [SP, 8], A ; pow
.L181:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L180
.L182:
  LD     A, [SP, 16] ; sign
  ITF    A, A
  LD     B, [SP, 4] ; val
  MULF   A, B
  LD     B, [SP, 8] ; pow
  DIVF   A, B
.L171:
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
  ADD    A, A, 8 ; 
  CALL   free
  LDI    A, =freehead
  LD     A, [A]
.L183:
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
  JNE    .L185
  LDI    B, =base
  ST     [SP, 8], B ; prevp
  LDI    A, =freehead
  ST     [A], B
  LDI    A, =base
  ST     [A, 0], B ; .next
  MOV    A, 0
  LDI    B, =base
  ST     [B, 4], A ; .size
.L185:
  LD     A, [SP, 8] ; prevp
  LD     A, [A, 0] ; .next
  ST     [SP, 4], A ; p
.L186:
  LD     A, [SP, 4] ; p
  LD     A, [A, 4] ; .size
  LD     B, [SP, 12] ; units
  CMP    A, B
  JCC    .L189
  LD     A, [SP, 4] ; p
  LD     A, [A, 4] ; .size
  LD     B, [SP, 12] ; units
  CMP    A, B
  JNE    .L191
  LD     A, [SP, 4] ; p
  LD     A, [A, 0] ; .next
  LD     B, [SP, 8] ; prevp
  ST     [B, 0], A ; .next
  JMP    .L190
.L191:
  LD     C, [SP, 4] ; p
  LD     A, [C, 4] ; .size
  LD     B, [SP, 12] ; units
  SUB    A, B
  ST     [C, 4], A ; .size
  LD     A, [SP, 4] ; p
  LD     B, [A, 4] ; .size
  ADD    A, B
  ST     [SP, 4], A ; p
  LD     A, [SP, 12] ; units
  LD     B, [SP, 4] ; p
  ST     [B, 4], A ; .size
.L190:
  LD     A, [SP, 8] ; prevp
  LDI    B, =freehead
  ST     [B], A
  LD     A, [SP, 4] ; p
  ADD    A, A, 8 ; 
  JMP    .L184
.L189:
  LD     B, [SP, 4] ; p
  LDI    A, =freehead
  LD     A, [A]
  CMP    B, A
  JNE    .L192
  LD     A, [SP, 12] ; units
  CALL   morecore
  ST     [SP, 4], A ; p
  CMP    A, 0
  JNE    .L193
  MOV    A, 0
  JMP    .L184
.L193:
.L192:
.L187:
  LD     A, [SP, 4] ; p
  ST     [SP, 8], A ; prevp
  LD     A, [SP, 4] ; p
  LD     A, [A, 0] ; .next
  ST     [SP, 4], A ; p
  JMP    .L186
.L188:
.L184:
  ADD    SP, 16
  POP    B, C, PC
free:
  PUSH   B, C
  SUB    SP, 12
  ST     [SP, 0], A ; original
  CMP    A, 0
  JEQ    .L194
  LD     A, [SP, 0] ; original
  SUB    A, 8
  ST     [SP, 4], A ; free
  LDI    A, =freehead
  LD     A, [A]
  ST     [SP, 8], A ; p
.L195:
  LD     A, [SP, 8] ; p
  LD     B, [SP, 4] ; free
  CMP    A, B
  JCS    .L198
  LD     B, [SP, 4] ; free
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  CMP    B, A
  JCC    .L197
.L198:
  LD     A, [SP, 8] ; p
  LD     B, [A, 0] ; .next
  CMP    A, B
  JCC    .L199
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  CMP    A, B
  JHI    .L200
  LD     B, [SP, 4] ; free
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  CMP    B, A
  JCS    .L199
.L200:
  JMP    .L197
.L199:
.L196:
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  ST     [SP, 8], A ; p
  JMP    .L195
.L197:
  LD     A, [SP, 4] ; free
  LD     B, [A, 4] ; .size
  ADD    B, A, B
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  CMP    B, A
  JNE    .L202
  LD     C, [SP, 4] ; free
  LD     B, [C, 4] ; .size
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  LD     A, [A, 4] ; .size
  ADD    A, B, A
  ST     [C, 4], A ; .size
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  LD     A, [A, 0] ; .next
  LD     B, [SP, 4] ; free
  ST     [B, 0], A ; .next
  JMP    .L201
.L202:
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  LD     B, [SP, 4] ; free
  ST     [B, 0], A ; .next
.L201:
  LD     A, [SP, 8] ; p
  LD     B, [A, 4] ; .size
  ADD    A, B
  LD     B, [SP, 4] ; free
  CMP    A, B
  JNE    .L204
  LD     C, [SP, 8] ; p
  LD     B, [C, 4] ; .size
  LD     A, [SP, 4] ; free
  LD     A, [A, 4] ; .size
  ADD    A, B, A
  ST     [C, 4], A ; .size
  LD     A, [SP, 4] ; free
  LD     A, [A, 0] ; .next
  LD     B, [SP, 8] ; p
  ST     [B, 0], A ; .next
  JMP    .L203
.L204:
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  ST     [B, 0], A ; .next
.L203:
  LD     A, [SP, 8] ; p
  LDI    B, =freehead
  ST     [B], A
.L194:
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
.L205:
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
.L207:
  LD     A, [SP, 20] ; i
  LD     B, [SP, 12] ; words
  CMP    A, B
  JCS    .L209
  MOV    C, 0
  LD     A, [SP, 24] ; p
  LD     B, [SP, 20] ; i
  ADD    A, B
  ST     [A], C
.L208:
  LD     A, [SP, 20] ; i
  ADD    A, 1
  ST     [SP, 20], A ; i
  JMP    .L207
.L209:
  MOV    A, 0
  ST     [SP, 28], A ; c
.L210:
  LD     A, [SP, 28] ; c
  LD     B, [SP, 16] ; tail
  CMP    A, B
  JCS    .L212
  MOV    C, 0
  LD     A, [SP, 24] ; p
  LD     B, [SP, 20] ; i
  ADD    A, B
  LD     B, [SP, 28] ; c
  ADD    A, B
  ST.B   [A], C
.L211:
  LD     A, [SP, 28] ; c
  ADD    A, 1
  ST     [SP, 28], A ; c
  JMP    .L210
.L212:
  LD     A, [SP, 24] ; p
.L206:
  ADD    SP, 32
  POP    C, PC
fgetc:
  PUSH   B, C
  SUB    SP, 5
  ST     [SP, 0], A ; stream
.L214:
  LD     A, [SP, 0] ; stream
  LD     B, [A, 4] ; .read
  LD     A, [A, 8] ; .write
  CMP    B, A
  JNE    .L215
  JMP    .L214
.L215:
  LD     A, [SP, 0] ; stream
  LD     B, [A, 0] ; .buffer
  LD     A, [A, 4] ; .read
  LD.B   A, [B, A]
  ST.B   [SP, 4], A ; c
  LD     C, [SP, 0] ; stream
  LD     A, [C, 4] ; .read
  ADD    A, 1
  LD     B, [C, 12] ; .size
  MOD    A, B
  ST     [C, 4], A ; .read
  LD.B   A, [SP, 4] ; c
.L213:
  ADD    SP, 5
  POP    B, C
  RET
getchar:
  PUSH   B, C
  SUB    SP, 1
.L217:
  LDI    A, =stdin
  LD     A, [A]
  LD     B, [A, 4] ; .read
  LD     A, [A, 8] ; .write
  CMP    B, A
  JNE    .L218
  JMP    .L217
.L218:
  LDI    A, =stdin
  LD     A, [A]
  LD     B, [A, 0] ; .buffer
  LD     A, [A, 4] ; .read
  LD.B   A, [B, A]
  ST.B   [SP, 0], A ; c
  LDI    A, =stdin
  LD     C, [A]
  LD     A, [C, 4] ; .read
  ADD    A, 1
  LD     B, [C, 12] ; .size
  MOD    A, B
  ST     [C, 4], A ; .read
  LD.B   A, [SP, 0] ; c
.L216:
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
  JLS    .L220
.L221:
  LD     B, [SP, 12] ; i
  LD     A, [SP, 4] ; n
  SUB    A, 1
  CMP    B, A
  JCS    .L222
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 16], A ; c
  CMP.B  A, 0
  JEQ    .L222
  LD.B   A, [SP, 16] ; c
  CMP.B  A, '\n'
  JEQ    .L222
  LD.B   A, [SP, 16] ; c
  CMP.B  A, '\b'
  JNE    .L224
  LD     A, [SP, 12] ; i
  CMP    A, 0
  JLS    .L224
  LD     A, [SP, 12] ; i
  SUB    A, 1
  ST     [SP, 12], A ; i
  JMP    .L223
.L224:
  LD.B   A, [SP, 16] ; c
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ST.B   [B, C], A
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
.L223:
  JMP    .L221
.L222:
.L220:
  MOV.B  A, '\0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ST.B   [B, C], A
  LD     A, [SP, 0] ; s
.L219:
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
.L225:
  ADD    SP, 8
  POP    C, PC
fputc:
  PUSH   C
  SUB    SP, 5
  ST.B   [SP, 0], A ; c
  ST     [SP, 1], B ; stream
  LD.B   B, [SP, 0] ; c
  LD     A, [SP, 1] ; stream
  LD     C, [A, 0] ; .buffer
  LD     A, [A, 8] ; .write
  ST.B   [C, A], B
  LD     C, [SP, 1] ; stream
  LD     A, [C, 8] ; .write
  ADD    A, 1
  LD     B, [C, 12] ; .size
  MOD    A, B
  ST     [C, 8], A ; .write
  MOV    A, 0
.L226:
  ADD    SP, 5
  POP    C
  RET
putchar:
  PUSH   B, C
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  LD.B   C, [SP, 0] ; c
  LDI    A, =stdout
  LD     A, [A]
  LD     B, [A, 0] ; .buffer
  LD     A, [A, 8] ; .write
  ST.B   [B, A], C
  MOV    A, 0
.L227:
  ADD    SP, 1
  POP    B, C
  RET
fputs:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; stream
.L229:
  LD     A, [SP, 0] ; s
  LD.B   A, [A]
  CMP.B  A, '\0'
  JEQ    .L230
  LD     A, [SP, 0] ; s
  LD.B   A, [A]
  LD     B, [SP, 4] ; stream
  CALL   fputc
  LD     A, [SP, 0] ; s
  ADD    A, 1
  ST     [SP, 0], A ; s
  JMP    .L229
.L230:
  MOV    A, 0
.L228:
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
.L231:
  ADD    SP, 4
  POP    B, PC
uprint:
  PUSH   LR
  SUB    SP, 4
  ST     [SP, 0], A ; n
  DIV    A, 10
  CMP    A, 0
  JEQ    .L232
  LD     A, [SP, 0] ; n
  DIV    A, 10
  CALL   uprint
.L232:
  LD     A, [SP, 0] ; n
  MOD    A, 10
  ADD    A, '0'
  CALL   putchar
  ADD    SP, 4
  POP    PC
oprint:
  PUSH   LR
  SUB    SP, 4
  ST     [SP, 0], A ; n
  SHR    A, 3
  CMP    A, 0
  JEQ    .L233
  LD     A, [SP, 0] ; n
  SHR    A, 3
  CALL   oprint
.L233:
  LD     A, [SP, 0] ; n
  AND    A, 7
  ADD    A, '0'
  CALL   putchar
  ADD    SP, 4
  POP    PC
dprint:
  PUSH   LR
  SUB    SP, 4
  ST     [SP, 0], A ; n
  CMP    A, 0
  JGE    .L234
  MOV.B  A, '-'
  CALL   putchar
  LD     A, [SP, 0] ; n
  NEG    A, A
  ST     [SP, 0], A ; n
.L234:
  LD     A, [SP, 0] ; n
  CALL   uprint
  ADD    SP, 4
  POP    PC
xprint:
  PUSH   LR
  SUB    SP, 5
  ST     [SP, 0], A ; n
  ST.B   [SP, 4], B ; uplo
  LD     A, [SP, 0] ; n
  SHR    A, 4
  CMP    A, 0
  JEQ    .L235
  LD     A, [SP, 0] ; n
  SHR    A, 4
  LD.B   B, [SP, 4] ; uplo
  CALL   xprint
.L235:
  LD     A, [SP, 0] ; n
  AND    A, 15
  CMP    A, 9
  JLS    .L237
  LD     A, [SP, 0] ; n
  AND    A, 15
  SUB    A, 10
  LD.B   B, [SP, 4] ; uplo
  ADD    A, B
  CALL   putchar
  JMP    .L236
.L237:
  LD     A, [SP, 0] ; n
  AND    A, 15
  ADD    A, '0'
  CALL   putchar
.L236:
  ADD    SP, 5
  POP    PC
fprint:
  PUSH   LR
  SUB    SP, 13
  ST     [SP, 0], A ; f
  ST.B   [SP, 4], B ; prec
  LD     A, [SP, 0] ; f
  LDI    B, 0 ; 0.0
  CMPF   A, B
  JGE    .L238
  MOV.B  A, '-'
  CALL   putchar
  LD     A, [SP, 0] ; f
  NEGF   A, A
  ST     [SP, 0], A ; f
.L238:
  LD     A, [SP, 0] ; f
  FTI    A, A
  ST     [SP, 5], A ; left
  CALL   uprint
  LD.B   A, [SP, 4] ; prec
  CMP    A, 0
  JLE    .L239
  MOV.B  A, '.'
  CALL   putchar
  LD     B, [SP, 0] ; f
  LD     A, [SP, 5] ; left
  ITF    A, A
  SUBF   A, B, A
  ST     [SP, 9], A ; right
.L240:
  LD     A, [SP, 9] ; right
  LDI    B, 1092616192 ; 10.0
  MULF   A, B
  ST     [SP, 9], A ; right
  FTI    A, A
  ADD    A, '0'
  CALL   putchar
  LD     B, [SP, 9] ; right
  FTI    A, B
  ITF    A, A
  SUBF   A, B, A
  ST     [SP, 9], A ; right
  LD.B   A, [SP, 4] ; prec
  SUB.B  A, 1
  ST.B   [SP, 4], A ; prec
  CMP    A, 0
  JGT    .L240
.L241:
.L239:
  ADD    SP, 13
  POP    PC
eprint:
  PUSH   LR
  SUB    SP, 9
  ST     [SP, 0], A ; f
  ST.B   [SP, 4], B ; prec
  LD     B, [SP, 0] ; f
  ITF    A, 0
  CMPF   B, A
  JGE    .L242
  MOV.B  A, '-'
  CALL   putchar
  LD     A, [SP, 0] ; f
  NEGF   A, A
  ST     [SP, 0], A ; f
.L242:
  MOV    A, 0
  ST     [SP, 5], A ; exp
  LD     A, [SP, 0] ; f
  CMPF   A, 0
  JEQ    .L243
.L244:
  LD     A, [SP, 0] ; f
  LDI    B, 1092616192 ; 10.0
  CMPF   A, B
  JLT    .L245
  LD     A, [SP, 5] ; exp
  ADD    A, 1
  ST     [SP, 5], A ; exp
  LD     A, [SP, 0] ; f
  LDI    B, 1092616192 ; 10.0
  DIVF   A, B
  ST     [SP, 0], A ; f
  JMP    .L244
.L245:
.L246:
  LD     A, [SP, 0] ; f
  LDI    B, 1065353216 ; 1.0
  CMPF   A, B
  JGE    .L247
  LD     A, [SP, 5] ; exp
  SUB    A, 1
  ST     [SP, 5], A ; exp
  LD     A, [SP, 0] ; f
  LDI    B, 1092616192 ; 10.0
  MULF   A, B
  ST     [SP, 0], A ; f
  JMP    .L246
.L247:
.L243:
  LD     A, [SP, 0] ; f
  LD.B   B, [SP, 4] ; prec
  CALL   fprint
  MOV.B  A, 'e'
  CALL   putchar
  LD     A, [SP, 5] ; exp
  CALL   dprint
  ADD    SP, 9
  POP    PC
printf:
  PUSH   A, B, C, D
  PUSH   B, C, LR
  SUB    SP, 17
  ADD    A, SP, 33 ; format
  ST     [SP, 4], A ; ap
  MOV    A, 0
  ST     [SP, 12], A ; n
  LD     A, [SP, 29] ; format
  ST     [SP, 8], A ; c
.L248:
  LD     A, [SP, 8] ; c
  LD.B   A, [A]
  CMP.B  A, 0
  JEQ    .L250
  LD     A, [SP, 8] ; c
  LD.B   A, [A]
  CMP.B  A, '%'
  JNE    .L252
  LD     A, [SP, 8] ; c
  ADD    A, 1
  ST     [SP, 8], A ; c
  MOV    A, 0
  ST.B   [SP, 16], A ; precision
  MOV.B  B, '0'
  LD     A, [SP, 8] ; c
  LD.B   A, [A]
  CMP.B  B, A
  JGT    .L253
  LD     A, [SP, 8] ; c
  LD.B   A, [A]
  CMP.B  A, '9'
  JGT    .L253
  LD     A, [SP, 8] ; c
  ADD    B, A, 1
  ST     [SP, 8], B ; c
  LD.B   A, [A]
  SUB.B  A, '0'
  ST.B   [SP, 16], A ; precision
.L253:
  LD     A, [SP, 8] ; c
  LD.B   A, [A]
  CMP.B  A, 'u'
  JEQ    .L256
  CMP.B  A, 'd'
  JEQ    .L257
  CMP.B  A, 'i'
  JEQ    .L258
  CMP.B  A, 'x'
  JEQ    .L259
  CMP.B  A, 'X'
  JEQ    .L260
  CMP.B  A, 'f'
  JEQ    .L261
  CMP.B  A, 'e'
  JEQ    .L262
  CMP.B  A, 's'
  JEQ    .L263
  CMP.B  A, 'c'
  JEQ    .L264
  CMP.B  A, 'o'
  JEQ    .L265
  CMP.B  A, 'n'
  JEQ    .L266
  JMP    .L267
.L256:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  CALL   uprint
  JMP    .L255
.L257:
.L258:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  CALL   dprint
  JMP    .L255
.L259:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  MOV.B  B, 'a'
  CALL   xprint
  JMP    .L255
.L260:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  MOV.B  B, 'A'
  CALL   xprint
  JMP    .L255
.L261:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  LD.B   B, [SP, 16] ; precision
  CALL   fprint
  JMP    .L255
.L262:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  LD.B   B, [SP, 16] ; precision
  CALL   eprint
  JMP    .L255
.L263:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  CALL   printf
  JMP    .L255
.L264:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD.B   A, [A]
  CALL   putchar
  JMP    .L255
.L265:
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  CALL   oprint
  JMP    .L255
.L266:
  LD     C, [SP, 12] ; n
  LD     A, [SP, 4] ; ap
  ADD    B, A, 4
  ST     [SP, 4], B ; ap
  LD     A, [A]
  ST     [A], C
  JMP    .L255
.L267:
  LD     A, [SP, 8] ; c
  LD.B   A, [A]
  CALL   putchar
.L255:
  JMP    .L251
.L252:
  LD     A, [SP, 8] ; c
  LD.B   A, [A]
  CALL   putchar
.L251:
.L249:
  LD     A, [SP, 8] ; c
  ADD    A, 1
  ST     [SP, 8], A ; c
  LD     A, [SP, 12] ; n
  ADD    A, 1
  ST     [SP, 12], A ; n
  JMP    .L248
.L250:
  MOV    A, 0
  ST     [SP, 4], A ; ap
  ADD    SP, 17
  POP    B, C, LR
  ADD    SP, 16
  RET
strlen:
  PUSH   B
  SUB    SP, 8
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 4], A ; l
.L269:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; l
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JEQ    .L270
  LD     A, [SP, 4] ; l
  ADD    A, 1
  ST     [SP, 4], A ; l
  JMP    .L269
.L270:
  LD     A, [SP, 4] ; l
.L268:
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
.L272:
  LD     A, [SP, 4] ; t
  LD     C, [SP, 8] ; i
  LD.B   A, [A, C]
  LD     B, [SP, 0] ; s
  ST.B   [B, C], A
  CMP.B  A, '\0'
  JEQ    .L274
.L273:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
  JMP    .L272
.L274:
  LD     A, [SP, 0] ; s
.L271:
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
.L276:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L278
  LD     A, [SP, 4] ; t
  LD     C, [SP, 12] ; i
  LD.B   A, [A, C]
  LD     B, [SP, 0] ; s
  ST.B   [B, C], A
  CMP.B  A, '\0'
  JEQ    .L278
.L277:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L276
.L278:
  LD     A, [SP, 0] ; s
.L275:
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
  JEQ    .L280
  LD     D, [SP, 4] ; p
  LD     B, [SP, 0] ; s
  MOV    A, B
  CALL   strlen
  ADD    C, A, 1
  MOV    A, D
  CALL   strncpy
.L280:
  LD     A, [SP, 4] ; p
.L279:
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
  JEQ    .L282
  LD     A, [SP, 8] ; p
  LD     B, [SP, 0] ; s
  LD     C, [SP, 4] ; n
  CALL   strncpy
.L282:
  LD     A, [SP, 8] ; p
.L281:
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
.L284:
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
  JEQ    .L285
  JMP    .L284
.L285:
  LD     A, [SP, 0] ; s
.L283:
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
.L287:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L288
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
  JEQ    .L288
  JMP    .L287
.L288:
  LD     A, [SP, 0] ; s
.L286:
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
.L290:
  LD     A, [SP, 4] ; front
  LD     B, [SP, 8] ; back
  CMP    A, B
  JCS    .L292
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; front
  LD.B   A, [A, B]
  ST.B   [SP, 12], A ; temp
  LD     C, [SP, 0] ; s
  LD     A, [SP, 8] ; back
  LD.B   A, [C, A]
  LD     B, [SP, 4] ; front
  ST.B   [C, B], A
  LD.B   A, [SP, 12] ; temp
  LD     B, [SP, 0] ; s
  LD     C, [SP, 8] ; back
  ST.B   [B, C], A
.L291:
  LD     A, [SP, 4] ; front
  ADD    A, 1
  ST     [SP, 4], A ; front
  LD     A, [SP, 8] ; back
  SUB    A, 1
  ST     [SP, 8], A ; back
  JMP    .L290
.L292:
  LD     A, [SP, 0] ; s
.L289:
  ADD    SP, 13
  POP    B, C, PC
strcmp:
  PUSH   C
  SUB    SP, 12
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  MOV    A, 0
  ST     [SP, 8], A ; i
.L294:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   C, [A, B]
  LD     A, [SP, 4] ; t
  LD.B   A, [A, B]
  CMP.B  C, A
  JNE    .L296
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JNE    .L297
  MOV    A, 0
  JMP    .L293
.L297:
.L295:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
  JMP    .L294
.L296:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   C, [A, B]
  LD     A, [SP, 4] ; t
  LD.B   A, [A, B]
  SUB.B  A, C, A
.L293:
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
.L299:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L301
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   C, [A, B]
  LD     A, [SP, 4] ; t
  LD.B   A, [A, B]
  CMP.B  C, A
  JNE    .L301
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JNE    .L302
  MOV    A, 0
  JMP    .L298
.L302:
.L300:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L299
.L301:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   C, [A, B]
  LD     A, [SP, 4] ; t
  LD.B   A, [A, B]
  SUB.B  A, C, A
.L298:
  ADD    SP, 16
  RET
strchr:
  SUB    SP, 9
  ST     [SP, 0], A ; s
  ST.B   [SP, 4], B ; c
  MOV    A, 0
  ST     [SP, 5], A ; i
.L304:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JEQ    .L306
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  LD.B   A, [A, B]
  LD.B   B, [SP, 4] ; c
  CMP.B  A, B
  JNE    .L307
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  ADD    A, A, B ; 
  JMP    .L303
.L307:
.L305:
  LD     A, [SP, 5] ; i
  ADD    A, 1
  ST     [SP, 5], A ; i
  JMP    .L304
.L306:
  MOV    A, 0
.L303:
  ADD    SP, 9
  RET
memset:
  SUB    SP, 13
  ST     [SP, 0], A ; s
  ST.B   [SP, 4], B ; v
  ST     [SP, 5], C ; n
  MOV    A, 0
  ST     [SP, 9], A ; i
.L309:
  LD     A, [SP, 9] ; i
  LD     B, [SP, 5] ; n
  CMP    A, B
  JCS    .L311
  LD.B   C, [SP, 4] ; v
  LD     A, [SP, 0] ; s
  LD     B, [SP, 9] ; i
  ADD    A, B
  ST.B   [A], C
.L310:
  LD     A, [SP, 9] ; i
  ADD    A, 1
  ST     [SP, 9], A ; i
  JMP    .L309
.L311:
  LD     A, [SP, 0] ; s
.L308:
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
.L313:
  LD     A, [SP, 17] ; i
  LD     B, [SP, 12] ; words
  CMP    A, B
  JCS    .L315
  LD     B, [SP, 4] ; t
  LD     A, [SP, 17] ; i
  SHL    C, A, 2
  ADD    A, B, C
  LD     B, [A]
  LD     A, [SP, 0] ; s
  ADD    A, C
  ST     [A], B
.L314:
  LD     A, [SP, 17] ; i
  ADD    A, 1
  ST     [SP, 17], A ; i
  JMP    .L313
.L315:
  MOV    A, 0
  ST.B   [SP, 21], A ; c
.L316:
  LD.B   A, [SP, 21] ; c
  LD.B   B, [SP, 16] ; tail
  CMP.B  A, B
  JGE    .L318
  LD     A, [SP, 4] ; t
  LD     C, [SP, 17] ; i
  ADD    A, C
  LD.B   D, [SP, 21] ; c
  ADD    A, D
  LD.B   B, [A]
  LD     A, [SP, 0] ; s
  ADD    A, C
  ADD    A, D
  ST.B   [A], B
.L317:
  LD.B   A, [SP, 21] ; c
  ADD.B  A, 1
  ST.B   [SP, 21], A ; c
  JMP    .L316
.L318:
  LD     A, [SP, 0] ; s
.L312:
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
.L320:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L322
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  ADD    A, B
  LD.B   C, [A]
  LD     A, [SP, 4] ; t
  ADD    A, B
  LD.B   A, [A]
  CMP.B  C, A
  JEQ    .L323
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  ADD    A, B
  LD.B   C, [A]
  LD     A, [SP, 4] ; t
  ADD    A, B
  LD.B   A, [A]
  SUB.B  A, C, A
  JMP    .L319
.L323:
.L321:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L320
.L322:
  MOV    A, 0
.L319:
  ADD    SP, 16
  RET
isupper:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV.B  A, 'A'
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L325
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'Z'
  JGT    .L325
  MOV    A, 1
  JMP    .L326
.L325:
  MOV    A, 0
.L324:
.L326:
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
  JGT    .L328
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'z'
  JGT    .L328
  MOV    A, 1
  JMP    .L329
.L328:
  MOV    A, 0
.L327:
.L329:
  ADD    SP, 1
  POP    B
  RET
isalpha:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   islower
  CMP    A, 0
  JNE    .L331
  LD.B   A, [SP, 0] ; c
  CALL   isupper
  CMP    A, 0
  JEQ    .L332
.L331:
  MOV    A, 1
  JMP    .L333
.L332:
  MOV    A, 0
.L330:
.L333:
  ADD    SP, 1
  POP    PC
iscntrl:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV    A, 0
  LD.B   B, [SP, 0] ; c
  CMP    A, B
  JGT    .L335
  LD.B   A, [SP, 0] ; c
  CMP    A, 32
  JGE    .L335
  MOV    A, 1
  JMP    .L336
.L335:
  MOV    A, 0
.L334:
.L336:
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
  JGT    .L338
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '9'
  JGT    .L338
  MOV    A, 1
  JMP    .L339
.L338:
  MOV    A, 0
.L337:
.L339:
  ADD    SP, 1
  POP    B
  RET
isalnum:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isalpha
  CMP    A, 0
  JNE    .L341
  LD.B   A, [SP, 0] ; c
  CALL   isdigit
  CMP    A, 0
  JEQ    .L342
.L341:
  MOV    A, 1
  JMP    .L343
.L342:
  MOV    A, 0
.L340:
.L343:
  ADD    SP, 1
  POP    PC
isspace:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP.B  A, ' '
  JEQ    .L345
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '\t'
  JEQ    .L345
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '\n'
  JNE    .L346
.L345:
  MOV    A, 1
  JMP    .L347
.L346:
  MOV    A, 0
.L344:
.L347:
  ADD    SP, 1
  RET
isxdigit:
  PUSH   B, LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isdigit
  CMP    A, 0
  JNE    .L349
  MOV.B  A, 'A'
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L352
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'F'
  JLE    .L349
.L352:
  MOV.B  A, 'a'
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGT    .L350
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'f'
  JGT    .L350
.L349:
  MOV    A, 1
  JMP    .L351
.L350:
  MOV    A, 0
.L348:
.L351:
  ADD    SP, 1
  POP    B, PC
tolower:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isupper
  CMP    A, 0
  JEQ    .L354
  LD.B   A, [SP, 0] ; c
  ADD.B  A, 'a'
  SUB.B  A, 'A'
  JMP    .L353
.L354:
  LD.B   A, [SP, 0] ; c
.L353:
  ADD    SP, 1
  POP    PC
toupper:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   islower
  CMP    A, 0
  JEQ    .L356
  LD.B   A, [SP, 0] ; c
  SUB.B  A, 'a'
  SUB.B  A, 'A'
  JMP    .L355
.L356:
  LD.B   A, [SP, 0] ; c
.L355:
  ADD    SP, 1
  POP    PC
isgraph:
  PUSH   B
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  MOV.B  A, ' '
  LD.B   B, [SP, 0] ; c
  CMP.B  A, B
  JGE    .L358
  LD.B   A, [SP, 0] ; c
  CMP    A, 127
  JGE    .L358
  MOV    A, 1
  JMP    .L359
.L358:
  MOV    A, 0
.L357:
.L359:
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
  JGT    .L361
  LD.B   A, [SP, 0] ; c
  CMP    A, 127
  JGE    .L361
  MOV    A, 1
  JMP    .L362
.L361:
  MOV    A, 0
.L360:
.L362:
  ADD    SP, 1
  POP    B
  RET
ispunct:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isgraph
  CMP    A, 0
  JEQ    .L364
  LD.B   A, [SP, 0] ; c
  CALL   isalnum
  CMP    A, 0
  JNE    .L364
  MOV    A, 1
  JMP    .L365
.L364:
  MOV    A, 0
.L363:
.L365:
  ADD    SP, 1
  POP    PC