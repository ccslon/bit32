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
buffer_base: .space 256
in_buffer:
  .word buffer_base
  .byte 0
  .byte 0
  .byte 0
  .byte 0
_stdin_base: .space 256
_stdout_base: .space 256
_stderr_base: .space 1
_stdin:
  .word _stdin_base
  .word 0
  .word 0
  .word 256
  .byte 2
  .word read_keyboard
  .word 0
_stdout:
  .word _stdout_base
  .word 0
  .word 0
  .word 256
  .byte 12
  .word 0
  .word write_teletype
_stderr:
  .word _stderr_base
  .word 0
  .word 0
  .word 1
  .byte 4
  .word 0
  .word write_teletype
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
  PUSH   B
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
  LD     B, [SP, 4] ; hash
  MUL    B, 31
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
  POP    B
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
  LD     A, [A, 8] ; .capacity
  SHL    A, 1
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
interrupt:
  PUSH   A, B, C, D, E, LR
  SUB    SP, 2
  MOV    A, 0
  ST.B   [SP, 0], A ; i
.L145:
  LD.B   A, [SP, 0] ; i
  CMP    A, 8
  JCS    .L147
  LDI    A, =in_buffer
  LD.B   A, [A, 6] ; .size
  CMP    A, 255
  JCS    .L147
  CALL   in
  ST.B   [SP, 1], A ; c
  CMP.B  A, '\0'
  JEQ    .L147
  LD.B   A, [SP, 1] ; c
  CALL   out
  LD.B   A, [SP, 1] ; c
  CMP.B  A, '\b'
  JNE    .L149
  LDI    A, =in_buffer
  LD.B   A, [A, 6] ; .size
  CMP    A, 0
  JLS    .L150
  LDI    B, =in_buffer
  LD.B   A, [B, 4] ; .read
  LD.B   B, [B, 5] ; .write
  CMP.B  A, B
  JEQ    .L150
  LDI    B, =in_buffer
  LD     A, [B, 0] ; .data
  LD.B   B, [B, 5] ; .write
  LD.B   A, [A, B]
  CMP.B  A, '\n'
  JEQ    .L150
  LDI    A, =in_buffer
  LD.B   B, [A, 5] ; .write
  SUB.B  B, 1
  ST.B   [A, 5], B ; .write
  LDI    A, =in_buffer
  LD.B   B, [A, 6] ; .size
  SUB.B  B, 1
  ST.B   [A, 6], B ; .size
.L150:
  JMP    .L148
.L149:
  LD.B   A, [SP, 1] ; c
  CMP.B  A, '\n'
  JNE    .L151
  LDI    A, =in_buffer
  LD.B   B, [A, 7] ; .ready
  ADD.B  B, 1
  ST.B   [A, 7], B ; .ready
.L151:
  LD.B   A, [SP, 1] ; c
  LDI    B, =in_buffer
  LD     C, [B, 0] ; .data
  LD.B   D, [B, 5] ; .write
  ADD.B  E, D, 1
  ST.B   [B, 5], E ; .write
  ST.B   [C, D], A
  LDI    A, =in_buffer
  LD.B   B, [A, 6] ; .size
  ADD.B  B, 1
  ST.B   [A, 6], B ; .size
.L148:
.L146:
  LD.B   A, [SP, 0] ; i
  ADD.B  A, 1
  ST.B   [SP, 0], A ; i
  JMP    .L145
.L147:
  ADD    SP, 2
  POP    A, B, C, D, E, PC
read_keyboard:
  PUSH   C, D
  SUB    SP, 13
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
.L153:
  LDI    A, =in_buffer
  LD.B   A, [A, 7] ; .ready
  CMP    A, 0
  JNE    .L154
  JMP    .L153
.L154:
  MOV    A, 0
  ST     [SP, 9], A ; i
.L155:
  LD     A, [SP, 9] ; i
  LD     B, [SP, 4] ; n
  CMP    A, B
  JCS    .L157
  LDI    A, =in_buffer
  LD.B   A, [A, 6] ; .size
  CMP    A, 0
  JLS    .L157
  LDI    A, =in_buffer
  LD.B   B, [A, 6] ; .size
  SUB.B  B, 1
  ST.B   [A, 6], B ; .size
  LDI    A, =in_buffer
  LD     B, [A, 0] ; .data
  LD.B   C, [A, 4] ; .read
  ADD.B  D, C, 1
  ST.B   [A, 4], D ; .read
  LD.B   A, [B, C]
  ST.B   [SP, 8], A ; c
  LD     B, [SP, 0] ; s
  LD     C, [SP, 9] ; i
  ADD    D, C, 1
  ST     [SP, 9], D ; i
  ST.B   [B, C], A
  LD.B   A, [SP, 8] ; c
  CMP.B  A, '\n'
  JNE    .L158
  LDI    A, =in_buffer
  LD.B   B, [A, 7] ; .ready
  SUB.B  B, 1
  ST.B   [A, 7], B ; .ready
  JMP    .L157
.L158:
.L156:
  JMP    .L155
.L157:
  LD     A, [SP, 9] ; i
.L152:
  ADD    SP, 13
  POP    C, D
  RET
write_teletype:
  PUSH   LR
  SUB    SP, 12
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  MOV    A, 0
  ST     [SP, 8], A ; i
.L159:
  LD     A, [SP, 8] ; i
  LD     B, [SP, 4] ; n
  CMP    A, B
  JCS    .L161
  LD     A, [SP, 0] ; s
  ADD    B, A, 1
  ST     [SP, 0], B ; s
  LD.B   A, [A]
  CALL   out
.L160:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
  JMP    .L159
.L161:
  ADD    SP, 12
  POP    PC
isupper:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP.B  A, 'A'
  JLT    .L163
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'Z'
  JGT    .L163
  MOV    A, 1
  JMP    .L164
.L163:
  MOV    A, 0
.L162:
.L164:
  ADD    SP, 1
  RET
islower:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP.B  A, 'a'
  JLT    .L166
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'z'
  JGT    .L166
  MOV    A, 1
  JMP    .L167
.L166:
  MOV    A, 0
.L165:
.L167:
  ADD    SP, 1
  RET
isalpha:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   islower
  CMP    A, 0
  JNE    .L169
  LD.B   A, [SP, 0] ; c
  CALL   isupper
  CMP    A, 0
  JEQ    .L170
.L169:
  MOV    A, 1
  JMP    .L171
.L170:
  MOV    A, 0
.L168:
.L171:
  ADD    SP, 1
  POP    PC
iscntrl:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP    A, 0
  JLT    .L173
  LD.B   A, [SP, 0] ; c
  CMP    A, 32
  JGE    .L173
  MOV    A, 1
  JMP    .L174
.L173:
  MOV    A, 0
.L172:
.L174:
  ADD    SP, 1
  RET
isdigit:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP.B  A, '0'
  JLT    .L176
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '9'
  JGT    .L176
  MOV    A, 1
  JMP    .L177
.L176:
  MOV    A, 0
.L175:
.L177:
  ADD    SP, 1
  RET
isalnum:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isalpha
  CMP    A, 0
  JNE    .L179
  LD.B   A, [SP, 0] ; c
  CALL   isdigit
  CMP    A, 0
  JEQ    .L180
.L179:
  MOV    A, 1
  JMP    .L181
.L180:
  MOV    A, 0
.L178:
.L181:
  ADD    SP, 1
  POP    PC
isspace:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP.B  A, ' '
  JEQ    .L183
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '\t'
  JEQ    .L183
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '\n'
  JNE    .L184
.L183:
  MOV    A, 1
  JMP    .L185
.L184:
  MOV    A, 0
.L182:
.L185:
  ADD    SP, 1
  RET
isxdigit:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isdigit
  CMP    A, 0
  JNE    .L187
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'A'
  JLT    .L190
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'F'
  JLE    .L187
.L190:
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'a'
  JLT    .L188
  LD.B   A, [SP, 0] ; c
  CMP.B  A, 'f'
  JGT    .L188
.L187:
  MOV    A, 1
  JMP    .L189
.L188:
  MOV    A, 0
.L186:
.L189:
  ADD    SP, 1
  POP    PC
tolower:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isupper
  CMP    A, 0
  JEQ    .L192
  LD.B   A, [SP, 0] ; c
  ADD.B  A, 'a'
  SUB.B  A, 'A'
  JMP    .L191
.L192:
  LD.B   A, [SP, 0] ; c
.L191:
  ADD    SP, 1
  POP    PC
toupper:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   islower
  CMP    A, 0
  JEQ    .L194
  LD.B   A, [SP, 0] ; c
  SUB.B  A, 'a'
  SUB.B  A, 'A'
  JMP    .L193
.L194:
  LD.B   A, [SP, 0] ; c
.L193:
  ADD    SP, 1
  POP    PC
isgraph:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP.B  A, ' '
  JLE    .L196
  LD.B   A, [SP, 0] ; c
  CMP    A, 127
  JGE    .L196
  MOV    A, 1
  JMP    .L197
.L196:
  MOV    A, 0
.L195:
.L197:
  ADD    SP, 1
  RET
isprint:
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CMP.B  A, ' '
  JLT    .L199
  LD.B   A, [SP, 0] ; c
  CMP    A, 127
  JGE    .L199
  MOV    A, 1
  JMP    .L200
.L199:
  MOV    A, 0
.L198:
.L200:
  ADD    SP, 1
  RET
ispunct:
  PUSH   LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  CALL   isgraph
  CMP    A, 0
  JEQ    .L202
  LD.B   A, [SP, 0] ; c
  CALL   isalnum
  CMP    A, 0
  JNE    .L202
  MOV    A, 1
  JMP    .L203
.L202:
  MOV    A, 0
.L201:
.L203:
  ADD    SP, 1
  POP    PC
fact:
  PUSH   B
  SUB    SP, 8
  ST     [SP, 0], A ; n
  MOV    A, 1
  ST     [SP, 4], A ; fact
.L205:
  LD     A, [SP, 0] ; n
  CMP    A, 0
  JLS    .L207
  LD     A, [SP, 4] ; fact
  LD     B, [SP, 0] ; n
  MUL    A, B
  ST     [SP, 4], A ; fact
.L206:
  LD     A, [SP, 0] ; n
  SUB    A, 1
  ST     [SP, 0], A ; n
  JMP    .L205
.L207:
  LD     A, [SP, 4] ; fact
.L204:
  ADD    SP, 8
  POP    B
  RET
sum:
  PUSH   C, D, LR
  SUB    SP, 16
  ST     [SP, 0], A ; x
  ST     [SP, 4], B ; f
  ITF    A, 0
  ST     [SP, 8], A ; sum
  MOV    A, 0
  ST     [SP, 12], A ; n
.L209:
  LD     A, [SP, 12] ; n
  CMP    A, 10
  JCS    .L211
  LD     C, [SP, 8] ; sum
  LD     A, [SP, 0] ; x
  LD     B, [SP, 12] ; n
  LD     D, [SP, 4] ; f
  CALL   D
  ADDF   A, C, A
  ST     [SP, 8], A ; sum
.L210:
  LD     A, [SP, 12] ; n
  ADD    A, 1
  ST     [SP, 12], A ; n
  JMP    .L209
.L211:
  LD     A, [SP, 8] ; sum
.L208:
  ADD    SP, 16
  POP    C, D, PC
pow:
  SUB    SP, 12
  ST     [SP, 0], A ; base
  ST     [SP, 4], B ; exp
  ITF    A, 1
  ST     [SP, 8], A ; pow
.L213:
  LD     A, [SP, 4] ; exp
  CMP    A, 0
  JLS    .L214
  LD     A, [SP, 8] ; pow
  LD     B, [SP, 0] ; base
  MULF   A, B
  ST     [SP, 8], A ; pow
  LD     A, [SP, 4] ; exp
  SUB    A, 1
  ST     [SP, 4], A ; exp
  JMP    .L213
.L214:
  LD     A, [SP, 8] ; pow
.L212:
  ADD    SP, 12
  RET
sin:
  PUSH   B, C, D, LR
  SUB    SP, 12
  ST     [SP, 0], A ; t
  ITF    A, 0
  ST     [SP, 4], A ; sin
  MOV    A, 0
  ST     [SP, 8], A ; n
.L216:
  LD     A, [SP, 8] ; n
  CMP    A, 10
  JCS    .L218
  LD     C, [SP, 4] ; sin
  ITF    A, -1
  LD     B, [SP, 8] ; n
  CALL   pow
  MOV    B, A
  LD     A, [SP, 8] ; n
  SHL    A, 1
  ADD    A, 1
  CALL   fact
  ITF    A, A
  DIVF   D, B, A
  LD     A, [SP, 0] ; t
  LD     B, [SP, 8] ; n
  SHL    B, 1
  ADD    B, 1
  CALL   pow
  MULF   A, D, A
  ADDF   A, C, A
  ST     [SP, 4], A ; sin
.L217:
  LD     A, [SP, 8] ; n
  ADD    A, 1
  ST     [SP, 8], A ; n
  JMP    .L216
.L218:
  LD     A, [SP, 4] ; sin
.L215:
  ADD    SP, 12
  POP    B, C, D, PC
fill:
  PUSH   B, C, D, LR
  SUB    SP, 4
  ST     [SP, 0], A ; stream
  LD.B   A, [A, 16] ; .flags
  AND    A, 1
  CMP    A, 0
  JEQ    .L220
  MOV    A, -1
  JMP    .L219
.L220:
  LD     A, [SP, 0] ; stream
  LD     A, [A, 0] ; .base
  CMP    A, 0
  JNE    .L221
  LD     A, [SP, 0] ; stream
  LD     A, [A, 12] ; .capacity
  CALL   malloc
  LD     B, [SP, 0] ; stream
  ST     [B, 0], A ; .base
  CMP    A, 0
  JNE    .L222
  MOV    A, -1
  JMP    .L219
.L222:
.L221:
  MOV    A, 0
  LD     B, [SP, 0] ; stream
  ST     [B, 4], A ; .index
  LD     C, [SP, 0] ; stream
  LD     A, [C, 0] ; .base
  LD     B, [C, 12] ; .capacity
  LD     C, [C, 17] ; .read
  CALL   C
  LD     B, [SP, 0] ; stream
  ST     [B, 8], A ; .size
  LD     A, [SP, 0] ; stream
  LD     A, [A, 8] ; .size
  CMP    A, 0
  JNE    .L223
  LD     A, [SP, 0] ; stream
  LD.B   B, [A, 16] ; .flags
  OR     B, 16
  ST.B   [A, 16], B ; .flags
  MOV    A, -1
  JMP    .L219
.L223:
  LD     A, [SP, 0] ; stream
  LD     B, [A, 8] ; .size
  SUB    B, 1
  ST     [A, 8], B ; .size
  LD     A, [SP, 0] ; stream
  LD     B, [A, 0] ; .base
  LD     C, [A, 4] ; .index
  ADD    D, C, 1
  ST     [A, 4], D ; .index
  LD.B   A, [B, C]
.L219:
  ADD    SP, 4
  POP    B, C, D, PC
fgetc:
  PUSH   B, C, D, LR
  SUB    SP, 4
  ST     [SP, 0], A ; stream
  LD     A, [A, 8] ; .size
  CMP    A, 0
  JNE    .L225
  LD     A, [SP, 0] ; stream
  CALL   fill
  JMP    .L224
.L225:
  LD     A, [SP, 0] ; stream
  LD     B, [A, 8] ; .size
  SUB    B, 1
  ST     [A, 8], B ; .size
  LD     A, [SP, 0] ; stream
  LD     B, [A, 0] ; .base
  LD     C, [A, 4] ; .index
  ADD    D, C, 1
  ST     [A, 4], D ; .index
  LD.B   A, [B, C]
.L224:
  ADD    SP, 4
  POP    B, C, D, PC
ungetc:
  PUSH   C, D
  SUB    SP, 5
  ST.B   [SP, 0], A ; c
  ST     [SP, 1], B ; stream
  LD.B   A, [SP, 0] ; c
  CMP    A, -1
  JEQ    .L227
  LD.B   A, [SP, 0] ; c
  LD     B, [SP, 1] ; stream
  LD     C, [B, 0] ; .base
  LD     D, [B, 4] ; .index
  SUB    D, 1
  ST     [B, 4], D ; .index
  ST.B   [C, D], A
  LD     A, [SP, 1] ; stream
  LD     B, [A, 8] ; .size
  ADD    B, 1
  ST     [A, 8], B ; .size
.L227:
  LD.B   A, [SP, 0] ; c
.L226:
  ADD    SP, 5
  POP    C, D
  RET
getchar:
  PUSH   LR
  LDI    A, =stdin
  LD     A, [A]
  CALL   fgetc
.L228:
  POP    PC
fgets:
  PUSH   D, LR
  SUB    SP, 17
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  ST     [SP, 8], C ; stream
  MOV    A, 0
  ST     [SP, 12], A ; i
  LD     A, [SP, 4] ; n
  CMP    A, 0
  JLS    .L230
.L231:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 4] ; n
  SUB    B, 1
  CMP    A, B
  JCS    .L232
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 16], A ; c
  CMP    A, -1
  JEQ    .L232
  LD.B   A, [SP, 16] ; c
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ADD    D, C, 1
  ST     [SP, 12], D ; i
  ST.B   [B, C], A
  LD.B   A, [SP, 16] ; c
  CMP.B  A, '\n'
  JNE    .L233
  JMP    .L232
.L233:
  JMP    .L231
.L232:
.L230:
  MOV.B  A, '\0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ST.B   [B, C], A
  LD     A, [SP, 0] ; s
.L229:
  ADD    SP, 17
  POP    D, PC
gets:
  PUSH   C, D, LR
  SUB    SP, 13
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  MOV    A, 0
  ST     [SP, 8], A ; i
  LD     A, [SP, 4] ; n
  CMP    A, 0
  JLS    .L235
.L236:
  LD     A, [SP, 8] ; i
  LD     B, [SP, 4] ; n
  SUB    B, 1
  CMP    A, B
  JCS    .L237
  CALL   getchar
  ST.B   [SP, 12], A ; c
  CMP    A, -1
  JEQ    .L237
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '\n'
  JNE    .L238
  JMP    .L237
.L238:
  LD.B   A, [SP, 12] ; c
  LD     B, [SP, 0] ; s
  LD     C, [SP, 8] ; i
  ADD    D, C, 1
  ST     [SP, 8], D ; i
  ST.B   [B, C], A
  JMP    .L236
.L237:
.L235:
  MOV.B  A, '\0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 8] ; i
  ST.B   [B, C], A
  LD     A, [SP, 0] ; s
.L234:
  ADD    SP, 13
  POP    C, D, PC
flush:
  PUSH   C, LR
  SUB    SP, 5
  ST     [SP, 0], A ; c
  ST     [SP, 1], B ; stream
  LD     A, [SP, 1] ; stream
  LD.B   A, [A, 16] ; .flags
  AND    A, 5
  CMP    A, 4
  JEQ    .L240
  MOV    A, -1
  JMP    .L239
.L240:
  LD     A, [SP, 1] ; stream
  LD     A, [A, 0] ; .base
  CMP    A, 0
  JNE    .L242
  LD     A, [SP, 1] ; stream
  LD     A, [A, 12] ; .capacity
  CALL   malloc
  LD     B, [SP, 1] ; stream
  ST     [B, 0], A ; .base
  CMP    A, 0
  JNE    .L243
  LD     A, [SP, 1] ; stream
  LD.B   B, [A, 16] ; .flags
  OR     B, 1
  ST.B   [A, 16], B ; .flags
  MOV    A, -1
  JMP    .L239
.L243:
  JMP    .L241
.L242:
  LD     C, [SP, 1] ; stream
  LD     A, [C, 0] ; .base
  LD     B, [C, 4] ; .index
  LD     C, [C, 21] ; .write
  CALL   C
  LD     B, [SP, 1] ; stream
  LD     B, [B, 4] ; .index
  CMP    A, B
  JEQ    .L244
  LD     A, [SP, 1] ; stream
  LD.B   B, [A, 16] ; .flags
  OR     B, 1
  ST.B   [A, 16], B ; .flags
  MOV    A, -1
  JMP    .L239
.L244:
.L241:
  MOV    A, 0
  LD     B, [SP, 1] ; stream
  ST     [B, 4], A ; .index
  LD     A, [SP, 1] ; stream
  LD     B, [A, 12] ; .capacity
  ST     [A, 8], B ; .size
  LD.B   A, [SP, 0] ; c
.L239:
  ADD    SP, 5
  POP    C, PC
fflush:
  PUSH   B, LR
  SUB    SP, 4
  ST     [SP, 0], A ; stream
  LD.B   A, [A, 16] ; .flags
  AND    A, 4
  CMP    A, 0
  JEQ    .L246
  MOV    A, 0
  LD     B, [SP, 0] ; stream
  CALL   flush
  JMP    .L245
.L246:
  MOV    A, 0
  LD     B, [SP, 0] ; stream
  ST     [B, 4], A ; .index
  LD     A, [SP, 0] ; stream
  LD     B, [A, 12] ; .capacity
  ST     [A, 8], B ; .size
  MOV    A, 0
.L245:
  ADD    SP, 4
  POP    B, PC
fputc:
  PUSH   C, D, E, LR
  SUB    SP, 5
  ST     [SP, 0], A ; c
  ST     [SP, 1], B ; stream
  LD     A, [SP, 1] ; stream
  LD     A, [A, 8] ; .size
  CMP    A, 0
  JNE    .L248
  LD.B   A, [SP, 0] ; c
  LD     B, [SP, 1] ; stream
  CALL   flush
  CMP    A, -1
  JNE    .L249
  MOV    A, -1
  JMP    .L247
.L249:
.L248:
  LD     A, [SP, 1] ; stream
  LD     B, [A, 8] ; .size
  SUB    B, 1
  ST     [A, 8], B ; .size
  LD.B   A, [SP, 0] ; c
  LD     B, [SP, 1] ; stream
  LD     C, [B, 0] ; .base
  LD     D, [B, 4] ; .index
  ADD    E, D, 1
  ST     [B, 4], E ; .index
  ST.B   [C, D], A
  LD     A, [SP, 1] ; stream
  LD.B   A, [A, 16] ; .flags
  AND    A, 8
  CMP    A, 0
  JEQ    .L252
  LD.B   A, [SP, 0] ; c
  CMP.B  A, '\n'
  JEQ    .L251
.L252:
  LD     A, [SP, 1] ; stream
  LD     A, [A, 12] ; .capacity
  CMP    A, 1
  JNE    .L250
.L251:
  LD.B   A, [SP, 0] ; c
  LD     B, [SP, 1] ; stream
  CALL   flush
  JMP    .L247
.L250:
  LD.B   A, [SP, 0] ; c
.L247:
  ADD    SP, 5
  POP    C, D, E, PC
putchar:
  PUSH   B, LR
  SUB    SP, 1
  ST.B   [SP, 0], A ; c
  LDI    B, =stdout
  LD     B, [B]
  CALL   fputc
.L253:
  ADD    SP, 1
  POP    B, PC
fputs:
  PUSH   LR
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  ST     [SP, 8], C ; stream
  MOV    A, 0
  ST     [SP, 12], A ; i
.L255:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 4] ; n
  CMP    A, B
  JCS    .L257
  LD     A, [SP, 0] ; s
  LD.B   A, [A]
  CMP.B  A, '\0'
  JEQ    .L257
  LD     A, [SP, 0] ; s
  LD.B   A, [A]
  LD     B, [SP, 8] ; stream
  CALL   fputc
  CMP    A, -1
  JNE    .L258
  LD     A, [SP, 8] ; stream
  LD.B   B, [A, 16] ; .flags
  OR     B, 1
  ST.B   [A, 16], B ; .flags
  MOV    A, -1
  JMP    .L254
.L258:
.L256:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  LD     A, [SP, 0] ; s
  ADD    A, 1
  ST     [SP, 0], A ; s
  JMP    .L255
.L257:
  MOV    A, 0
.L254:
  ADD    SP, 16
  POP    PC
puts:
  PUSH   B, C, LR
  SUB    SP, 4
  ST     [SP, 0], A ; s
  LDI    B, 256
  LDI    C, =stdout
  LD     C, [C]
  CALL   fputs
  MOV.B  A, '\n'
  CALL   putchar
  MOV    A, 0
.L259:
  ADD    SP, 4
  POP    B, C, PC
uprint:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; n
  LD     A, [SP, 4] ; n
  DIV    A, 10
  CMP    A, 0
  JEQ    .L260
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 4] ; n
  DIV    B, 10
  CALL   uprint
.L260:
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
  JEQ    .L261
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 4] ; n
  SHR    B, 3
  CALL   oprint
.L261:
  LD     A, [SP, 4] ; n
  AND    A, 7
  ADD    A, '0'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  ADD    SP, 8
  POP    PC
dprint:
  PUSH   LR
  SUB    SP, 8
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; n
  LD     A, [SP, 4] ; n
  CMP    A, 0
  JGE    .L262
  MOV.B  A, '-'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 4] ; n
  NEG    A, A
  ST     [SP, 4], A ; n
.L262:
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
  JEQ    .L263
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 4] ; n
  SHR    B, 4
  LD.B   C, [SP, 8] ; uplo
  CALL   xprint
.L263:
  LD     A, [SP, 4] ; n
  AND    A, 15
  CMP    A, 9
  JLS    .L265
  LD     A, [SP, 4] ; n
  AND    A, 15
  SUB    A, 10
  LD.B   B, [SP, 8] ; uplo
  ADD    A, B
  LD     B, [SP, 0] ; stream
  CALL   fputc
  JMP    .L264
.L265:
  LD     A, [SP, 4] ; n
  AND    A, 15
  ADD    A, '0'
  LD     B, [SP, 0] ; stream
  CALL   fputc
.L264:
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
  JGE    .L266
  MOV.B  A, '-'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 4] ; f
  NEGF   A, A
  ST     [SP, 4], A ; f
.L266:
  LD     A, [SP, 4] ; f
  FTI    A, A
  ST     [SP, 9], A ; left
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 9] ; left
  CALL   uprint
  LD.B   A, [SP, 8] ; prec
  CMP    A, 0
  JLE    .L267
  MOV.B  A, '.'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 4] ; f
  LD     B, [SP, 9] ; left
  ITF    B, B
  SUBF   A, B
  ST     [SP, 13], A ; right
.L268:
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
  JGT    .L268
.L269:
.L267:
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
  JGE    .L270
  MOV.B  A, '-'
  LD     B, [SP, 0] ; stream
  CALL   fputc
  LD     A, [SP, 4] ; f
  NEGF   A, A
  ST     [SP, 4], A ; f
.L270:
  MOV    A, 0
  ST     [SP, 9], A ; exp
  LD     A, [SP, 4] ; f
  CMPF   A, 0
  JEQ    .L271
.L272:
  LD     A, [SP, 4] ; f
  LDI    B, 1092616192 ; 10.0
  CMPF   A, B
  JLT    .L273
  LD     A, [SP, 9] ; exp
  ADD    A, 1
  ST     [SP, 9], A ; exp
  LD     A, [SP, 4] ; f
  LDI    B, 1092616192 ; 10.0
  DIVF   A, B
  ST     [SP, 4], A ; f
  JMP    .L272
.L273:
.L274:
  LD     A, [SP, 4] ; f
  LDI    B, 1065353216 ; 1.0
  CMPF   A, B
  JGE    .L275
  LD     A, [SP, 9] ; exp
  SUB    A, 1
  ST     [SP, 9], A ; exp
  LD     A, [SP, 4] ; f
  LDI    B, 1092616192 ; 10.0
  MULF   A, B
  ST     [SP, 4], A ; f
  JMP    .L274
.L275:
.L271:
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
.L277:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, 0
  JEQ    .L279
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, '%'
  JNE    .L281
  LD     A, [SP, 12] ; c
  ADD    A, 1
  ST     [SP, 12], A ; c
  MOV    A, 0
  ST.B   [SP, 20], A ; precision
.L282:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CALL   isdigit
  CMP    A, 0
  JEQ    .L283
  LD.B   A, [SP, 20] ; precision
  MUL    A, 10
  LD     B, [SP, 12] ; c
  ADD    C, B, 1
  ST     [SP, 12], C ; c
  LD.B   B, [B]
  SUB.B  B, '0'
  ADD    A, B
  ST.B   [SP, 20], A ; precision
  JMP    .L282
.L283:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, 'u'
  JEQ    .L286
  CMP.B  A, 'd'
  JEQ    .L287
  CMP.B  A, 'i'
  JEQ    .L288
  CMP.B  A, 'x'
  JEQ    .L289
  CMP.B  A, 'X'
  JEQ    .L290
  CMP.B  A, 'f'
  JEQ    .L291
  CMP.B  A, 'e'
  JEQ    .L292
  CMP.B  A, 's'
  JEQ    .L293
  CMP.B  A, 'c'
  JEQ    .L294
  CMP.B  A, 'o'
  JEQ    .L295
  CMP.B  A, 'n'
  JEQ    .L296
  JMP    .L297
.L286:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  CALL   uprint
  JMP    .L285
.L287:
.L288:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  CALL   dprint
  JMP    .L285
.L289:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  MOV.B  C, 'a'
  CALL   xprint
  JMP    .L285
.L290:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  MOV.B  C, 'A'
  CALL   xprint
  JMP    .L285
.L291:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  LD.B   C, [SP, 20] ; precision
  CALL   fprint
  JMP    .L285
.L292:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  LD.B   C, [SP, 20] ; precision
  CALL   eprint
  JMP    .L285
.L293:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  CALL   fprintf
  JMP    .L285
.L294:
  LD     A, [SP, 8] ; ap
  ADD    B, A, 4
  ST     [SP, 8], B ; ap
  LD.B   A, [A]
  LD     B, [SP, 0] ; stream
  CALL   fputc
  JMP    .L285
.L295:
  LD     A, [SP, 0] ; stream
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  CALL   oprint
  JMP    .L285
.L296:
  LD     A, [SP, 16] ; n
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  ST     [B], A
  JMP    .L285
.L297:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  LD     B, [SP, 0] ; stream
  CALL   fputc
.L285:
  JMP    .L280
.L281:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  LD     B, [SP, 0] ; stream
  CALL   fputc
.L280:
.L278:
  LD     A, [SP, 12] ; c
  ADD    A, 1
  ST     [SP, 12], A ; c
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
  JMP    .L277
.L279:
  LD     A, [SP, 16] ; n
.L276:
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
.L298:
  ADD    SP, 8
  POP    C, PC
fake_write:
  SUB    SP, 8
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  MOV    A, 0
.L299:
  ADD    SP, 8
  RET
vsnprintf:
  PUSH   LR
  SUB    SP, 45
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
  MOV    B, 4
  ST.B   [A, 16], B
  MOV    B, 0
  ST     [A, 17], B
  LDI    B, =fake_write
  ST     [A, 21], B
  ADD    A, SP, 20 ; fake
  LD     B, [SP, 8] ; format
  LD     C, [SP, 12] ; ap
  CALL   vfprintf
  ST     [SP, 16], A ; ret
  MOV.B  A, '\0'
  ADD    B, SP, 20 ; fake
  CALL   fputc
  LD     A, [SP, 16] ; ret
.L300:
  ADD    SP, 45
  POP    PC
fprintf:
  PUSH   A, B, C, D
  PUSH   C, LR
  SUB    SP, 8
  ADD    A, SP, 24 ; format+1
  ST     [SP, 4], A ; ap
  LD     A, [SP, 16] ; stream
  LD     B, [SP, 20] ; format
  LD     C, [SP, 4] ; ap
  CALL   vfprintf
  ST     [SP, 0], A ; ret
  MOV    A, 0
  ST     [SP, 4], A ; ap
  LD     A, [SP, 0] ; ret
.L301:
  ADD    SP, 8
  POP    C, LR
  ADD    SP, 16
  RET
printf:
  PUSH   A, B, C, D
  PUSH   B, LR
  SUB    SP, 8
  ADD    A, SP, 20 ; format+1
  ST     [SP, 4], A ; ap
  LD     A, [SP, 16] ; format
  LD     B, [SP, 4] ; ap
  CALL   vprintf
  ST     [SP, 0], A ; ret
  MOV    A, 0
  ST     [SP, 4], A ; ap
  LD     A, [SP, 0] ; ret
.L302:
  ADD    SP, 8
  POP    B, LR
  ADD    SP, 16
  RET
snprintf:
  PUSH   A, B, C, D
  PUSH   D, LR
  SUB    SP, 8
  ADD    A, SP, 28 ; format+1
  ST     [SP, 4], A ; ap
  LD     A, [SP, 16] ; s
  LD     B, [SP, 20] ; n
  LD     C, [SP, 24] ; format
  LD     D, [SP, 4] ; ap
  CALL   vsnprintf
  ST     [SP, 0], A ; ret
  MOV    A, 0
  ST     [SP, 4], A ; ap
  LD     A, [SP, 0] ; ret
.L303:
  ADD    SP, 8
  POP    D, LR
  ADD    SP, 16
  RET
uscan:
  PUSH   LR
  SUB    SP, 21
  ST     [SP, 0], A ; ptr
  ST     [SP, 4], B ; width
  ST     [SP, 8], C ; stream
.L305:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CALL   isspace
  CMP    A, 0
  JEQ    .L306
  JMP    .L305
.L306:
  LD.B   A, [SP, 12] ; c
  CALL   isdigit
  CMP    A, 0
  JNE    .L307
  MOV    A, 1
  JMP    .L304
.L307:
  MOV    A, 0
  ST     [SP, 17], A ; u
  MOV    A, 0
  ST     [SP, 13], A ; i
.L308:
  LD     A, [SP, 13] ; i
  LD     B, [SP, 4] ; width
  CMP    A, B
  JCS    .L310
  LD.B   A, [SP, 12] ; c
  CALL   isdigit
  CMP    A, 0
  JEQ    .L310
  LD     A, [SP, 17] ; u
  MUL    A, 10
  LD.B   B, [SP, 12] ; c
  SUB.B  B, '0'
  ADD    A, B
  ST     [SP, 17], A ; u
.L309:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  LD     A, [SP, 13] ; i
  ADD    A, 1
  ST     [SP, 13], A ; i
  JMP    .L308
.L310:
  LD.B   A, [SP, 12] ; c
  LD     B, [SP, 8] ; stream
  CALL   ungetc
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JEQ    .L311
  LD     A, [SP, 17] ; u
  LD     B, [SP, 0] ; ptr
  ST     [B], A
.L311:
  MOV    A, 0
.L304:
  ADD    SP, 21
  POP    PC
dscan:
  PUSH   LR
  SUB    SP, 25
  ST     [SP, 0], A ; ptr
  ST     [SP, 4], B ; width
  ST     [SP, 8], C ; stream
.L313:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CALL   isspace
  CMP    A, 0
  JEQ    .L314
  JMP    .L313
.L314:
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '-'
  JNE    .L316
  MOV    A, -1
  JMP    .L315
.L316:
  MOV    A, 1
.L315:
  ST     [SP, 21], A ; sign
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '-'
  JEQ    .L318
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '+'
  JNE    .L317
.L318:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
.L317:
  LD.B   A, [SP, 12] ; c
  CALL   isdigit
  CMP    A, 0
  JNE    .L319
  MOV    A, 1
  JMP    .L312
.L319:
  MOV    A, 0
  ST     [SP, 17], A ; d
  MOV    A, 0
  ST     [SP, 13], A ; i
.L320:
  LD     A, [SP, 13] ; i
  LD     B, [SP, 4] ; width
  CMP    A, B
  JCS    .L322
  LD.B   A, [SP, 12] ; c
  CALL   isdigit
  CMP    A, 0
  JEQ    .L322
  LD     A, [SP, 17] ; d
  MUL    A, 10
  LD.B   B, [SP, 12] ; c
  SUB.B  B, '0'
  ADD    A, B
  ST     [SP, 17], A ; d
.L321:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  LD     A, [SP, 13] ; i
  ADD    A, 1
  ST     [SP, 13], A ; i
  JMP    .L320
.L322:
  LD.B   A, [SP, 12] ; c
  LD     B, [SP, 8] ; stream
  CALL   ungetc
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JEQ    .L323
  LD     A, [SP, 21] ; sign
  LD     B, [SP, 17] ; d
  MUL    A, B
  LD     B, [SP, 0] ; ptr
  ST     [B], A
.L323:
  MOV    A, 0
.L312:
  ADD    SP, 25
  POP    PC
oscan:
  PUSH   LR
  SUB    SP, 21
  ST     [SP, 0], A ; ptr
  ST     [SP, 4], B ; width
  ST     [SP, 8], C ; stream
.L325:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CALL   isspace
  CMP    A, 0
  JEQ    .L326
  JMP    .L325
.L326:
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '0'
  JLT    .L328
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '7'
  JLE    .L327
.L328:
  MOV    A, 1
  JMP    .L324
.L327:
  MOV    A, 0
  ST     [SP, 17], A ; o
  MOV    A, 0
  ST     [SP, 13], A ; i
.L329:
  LD     A, [SP, 13] ; i
  LD     B, [SP, 4] ; width
  CMP    A, B
  JCS    .L331
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '0'
  JLT    .L331
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '7'
  JGT    .L331
  LD     B, [SP, 17] ; o
  SHL    A, B, 3
  SUB    B, '0'
  ADD    A, B
  ST     [SP, 17], A ; o
.L330:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  LD     A, [SP, 13] ; i
  ADD    A, 1
  ST     [SP, 13], A ; i
  JMP    .L329
.L331:
  LD.B   A, [SP, 12] ; c
  LD     B, [SP, 8] ; stream
  CALL   ungetc
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JEQ    .L332
  LD     A, [SP, 17] ; o
  LD     B, [SP, 0] ; ptr
  ST     [B], A
.L332:
  MOV    A, 0
.L324:
  ADD    SP, 21
  POP    PC
xscan:
  PUSH   LR
  SUB    SP, 21
  ST     [SP, 0], A ; ptr
  ST     [SP, 4], B ; width
  ST     [SP, 8], C ; stream
.L334:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CALL   isspace
  CMP    A, 0
  JEQ    .L335
  JMP    .L334
.L335:
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '0'
  JNE    .L336
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CMP.B  A, 'x'
  JEQ    .L337
  LD.B   A, [SP, 12] ; c
  CMP.B  A, 'X'
  JEQ    .L337
  MOV    A, 1
  JMP    .L333
.L337:
.L336:
  LD.B   A, [SP, 12] ; c
  CALL   isxdigit
  CMP    A, 0
  JNE    .L338
  MOV    A, 1
  JMP    .L333
.L338:
  MOV    A, 0
  ST     [SP, 17], A ; x
  MOV    A, 0
  ST     [SP, 13], A ; i
.L339:
  LD     A, [SP, 13] ; i
  LD     B, [SP, 4] ; width
  CMP    A, B
  JCS    .L341
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CMP.B  A, 0
  JEQ    .L341
  LD.B   A, [SP, 12] ; c
  CALL   isxdigit
  CMP    A, 0
  JEQ    .L341
  LD.B   A, [SP, 12] ; c
  CALL   isdigit
  CMP    A, 0
  JEQ    .L343
  LD     A, [SP, 17] ; x
  SHL    A, 4
  LD.B   B, [SP, 12] ; c
  SUB.B  B, '0'
  ADD    A, B
  ST.B   [SP, 12], A ; c
  JMP    .L342
.L343:
  LD     A, [SP, 17] ; x
  SHL    B, A, 4
  LD.B   A, [SP, 12] ; c
  ADD    C, A, 10
  CALL   isupper
  CMP    A, 0
  JEQ    .L345
  MOV.B  A, 'A'
  JMP    .L344
.L345:
  MOV.B  A, 'a'
.L344:
  SUB    A, C, A
  ADD    A, B, A
  ST.B   [SP, 12], A ; c
.L342:
.L340:
  LD     A, [SP, 13] ; i
  ADD    A, 1
  ST     [SP, 13], A ; i
  JMP    .L339
.L341:
  LD.B   A, [SP, 12] ; c
  LD     B, [SP, 8] ; stream
  CALL   ungetc
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JEQ    .L346
  LD     A, [SP, 17] ; x
  LD     B, [SP, 0] ; ptr
  ST     [B], A
.L346:
  MOV    A, 0
.L333:
  ADD    SP, 21
  POP    PC
iscan:
  PUSH   LR
  SUB    SP, 13
  ST     [SP, 0], A ; ptr
  ST     [SP, 4], B ; width
  ST     [SP, 8], C ; stream
.L348:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CALL   isspace
  CMP    A, 0
  JEQ    .L349
  JMP    .L348
.L349:
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '0'
  JNE    .L350
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CMP.B  A, 'x'
  JEQ    .L352
  LD.B   A, [SP, 12] ; c
  CMP.B  A, 'X'
  JNE    .L351
.L352:
  LD     A, [SP, 0] ; ptr
  LD     B, [SP, 4] ; width
  LD     C, [SP, 8] ; stream
  CALL   xscan
  JMP    .L347
.L351:
  LD     A, [SP, 0] ; ptr
  LD     B, [SP, 4] ; width
  LD     C, [SP, 8] ; stream
  CALL   oscan
  JMP    .L347
.L350:
  LD     A, [SP, 0] ; ptr
  LD     B, [SP, 4] ; width
  LD     C, [SP, 8] ; stream
  CALL   dscan
.L347:
  ADD    SP, 13
  POP    PC
fscan:
  PUSH   LR
  SUB    SP, 29
  ST     [SP, 0], A ; ptr
  ST     [SP, 4], B ; width
  ST     [SP, 8], C ; stream
.L354:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CALL   isspace
  CMP    A, 0
  JEQ    .L355
  JMP    .L354
.L355:
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '-'
  JNE    .L357
  MOV    A, -1
  JMP    .L356
.L357:
  MOV    A, 1
.L356:
  ITF    A, A
  ST     [SP, 17], A ; sign
  LD.B   A, [SP, 12] ; c
  CALL   isdigit
  CMP    A, 0
  JNE    .L358
  MOV    A, 1
  JMP    .L353
.L358:
  ITF    A, 0
  ST     [SP, 21], A ; f
  MOV    A, 0
  ST     [SP, 13], A ; i
.L359:
  LD     A, [SP, 13] ; i
  LD     B, [SP, 4] ; width
  CMP    A, B
  JCS    .L361
  LD.B   A, [SP, 12] ; c
  CALL   isdigit
  CMP    A, 0
  JEQ    .L361
  LD     A, [SP, 21] ; f
  ITF    B, 10
  MULF   A, B
  LD.B   B, [SP, 12] ; c
  SUB.B  B, '0'
  ITF    B, B
  ADDF   A, B
  ST     [SP, 21], A ; f
.L360:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  LD     A, [SP, 13] ; i
  ADD    A, 1
  ST     [SP, 13], A ; i
  JMP    .L359
.L361:
  LD.B   A, [SP, 12] ; c
  CMP.B  A, '.'
  JEQ    .L362
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JEQ    .L363
  LD     A, [SP, 17] ; sign
  LD     B, [SP, 21] ; f
  MULF   A, B
  LD     B, [SP, 0] ; ptr
  ST     [B], A
.L363:
  MOV    A, 0
  JMP    .L353
.L362:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CALL   isdigit
  CMP    A, 0
  JNE    .L364
  MOV    A, 1
  JMP    .L353
.L364:
  ITF    A, 1
  ST     [SP, 25], A ; pow
.L365:
  LD     A, [SP, 13] ; i
  LD     B, [SP, 4] ; width
  CMP    A, B
  JCS    .L367
  LD.B   A, [SP, 12] ; c
  CALL   isdigit
  CMP    A, 0
  JEQ    .L367
  LD     A, [SP, 21] ; f
  ITF    B, 10
  MULF   A, B
  LD.B   B, [SP, 12] ; c
  SUB    B, 10
  ITF    B, B
  ADDF   A, B
  ST     [SP, 21], A ; f
  LD     A, [SP, 25] ; pow
  ITF    B, 10
  MULF   A, B
  ST     [SP, 25], A ; pow
.L366:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  LD     A, [SP, 13] ; i
  ADD    A, 1
  ST     [SP, 13], A ; i
  JMP    .L365
.L367:
  LD.B   A, [SP, 12] ; c
  LD     B, [SP, 8] ; stream
  CALL   ungetc
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JEQ    .L368
  LD     A, [SP, 17] ; sign
  LD     B, [SP, 21] ; f
  MULF   A, B
  LD     B, [SP, 25] ; pow
  DIVF   A, B
  LD     B, [SP, 0] ; ptr
  ST     [B], A
.L368:
  MOV    A, 0
.L353:
  ADD    SP, 29
  POP    PC
escan:
  PUSH   LR
  SUB    SP, 21
  ST     [SP, 0], A ; ptr
  ST     [SP, 4], B ; width
  ST     [SP, 8], C ; stream
  ADD    A, SP, 13 ; e
  LD     B, [SP, 4] ; width
  LD     C, [SP, 8] ; stream
  CALL   fscan
  CMP    A, 0
  JEQ    .L370
  MOV    A, 1
  JMP    .L369
.L370:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CMP.B  A, 'e'
  JEQ    .L371
  LD.B   A, [SP, 12] ; c
  CMP.B  A, 'E'
  JEQ    .L371
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JEQ    .L372
  LD     A, [SP, 13] ; e
  LD     B, [SP, 0] ; ptr
  ST     [B], A
.L372:
  MOV    A, 0
  JMP    .L369
.L371:
  ADD    A, SP, 17 ; exp
  LD     B, [SP, 4] ; width
  LD     C, [SP, 8] ; stream
  CALL   dscan
  CMP    A, 0
  JEQ    .L373
  MOV    A, 1
  JMP    .L369
.L373:
.L374:
  LD     A, [SP, 17] ; exp
  CMP    A, 0
  JGE    .L376
  LD     A, [SP, 13] ; e
  ITF    B, 10
  DIVF   A, B
  ST     [SP, 13], A ; e
.L375:
  LD     A, [SP, 17] ; exp
  ADD    A, 1
  ST     [SP, 17], A ; exp
  JMP    .L374
.L376:
.L377:
  LD     A, [SP, 17] ; exp
  CMP    A, 0
  JLE    .L379
  LD     A, [SP, 13] ; e
  ITF    B, 10
  MULF   A, B
  ST     [SP, 13], A ; e
.L378:
  LD     A, [SP, 17] ; exp
  SUB    A, 1
  ST     [SP, 17], A ; exp
  JMP    .L377
.L379:
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JEQ    .L380
  LD     A, [SP, 13] ; e
  LD     B, [SP, 0] ; ptr
  ST     [B], A
.L380:
  MOV    A, 0
.L369:
  ADD    SP, 21
  POP    PC
sscan:
  PUSH   LR
  SUB    SP, 17
  ST     [SP, 0], A ; ptr
  ST     [SP, 4], B ; width
  ST     [SP, 8], C ; stream
.L382:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  CALL   isspace
  CMP    A, 0
  JEQ    .L383
  JMP    .L382
.L383:
  LD     A, [SP, 0] ; ptr
  CMP    A, 0
  JNE    .L385
  MOV    A, 0
  ST     [SP, 13], A ; i
.L386:
  LD     A, [SP, 13] ; i
  LD     B, [SP, 4] ; width
  CMP    A, B
  JCS    .L388
  LD.B   A, [SP, 12] ; c
  CMP.B  A, 0
  JEQ    .L388
  LD.B   A, [SP, 12] ; c
  CALL   isspace
  CMP    A, 0
  JNE    .L388
.L387:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  LD     A, [SP, 13] ; i
  ADD    A, 1
  ST     [SP, 13], A ; i
  JMP    .L386
.L388:
  JMP    .L384
.L385:
  MOV    A, 0
  ST     [SP, 13], A ; i
.L389:
  LD     A, [SP, 13] ; i
  LD     B, [SP, 4] ; width
  CMP    A, B
  JCS    .L391
  LD.B   A, [SP, 12] ; c
  CMP.B  A, 0
  JEQ    .L391
  LD.B   A, [SP, 12] ; c
  CALL   isspace
  CMP    A, 0
  JNE    .L391
  LD.B   A, [SP, 12] ; c
  LD     B, [SP, 0] ; ptr
  LD     C, [SP, 13] ; i
  ST.B   [B, C], A
.L390:
  LD     A, [SP, 8] ; stream
  CALL   fgetc
  ST.B   [SP, 12], A ; c
  LD     A, [SP, 13] ; i
  ADD    A, 1
  ST     [SP, 13], A ; i
  JMP    .L389
.L391:
  MOV.B  A, '\0'
  LD     B, [SP, 0] ; ptr
  LD     C, [SP, 13] ; i
  ST.B   [B, C], A
.L384:
  LD.B   A, [SP, 12] ; c
  LD     B, [SP, 8] ; stream
  CALL   ungetc
  MOV    A, 0
.L381:
  ADD    SP, 17
  POP    PC
vfscanf:
  PUSH   LR
  SUB    SP, 25
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; format
  ST     [SP, 8], C ; ap
  MOV    A, 0
  ST     [SP, 16], A ; n
  LD     A, [SP, 4] ; format
  ST     [SP, 12], A ; c
.L393:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, 0
  JEQ    .L395
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, '%'
  JNE    .L397
  MOV    A, 0
  ST.B   [SP, 20], A ; ignore
  LD     A, [SP, 12] ; c
  ADD    A, 1
  ST     [SP, 12], A ; c
  LD.B   A, [A]
  CMP.B  A, '\0'
  JNE    .L398
  LD     A, [SP, 16] ; n
  JMP    .L392
.L398:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, '*'
  JNE    .L399
  MOV    A, 1
  ST.B   [SP, 20], A ; ignore
  LD     A, [SP, 12] ; c
  ADD    A, 1
  ST     [SP, 12], A ; c
.L399:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CALL   isdigit
  CMP    A, 0
  JEQ    .L401
  MOV    A, 0
  ST     [SP, 21], A ; width
.L402:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CALL   isdigit
  CMP    A, 0
  JEQ    .L403
  LD     A, [SP, 21] ; width
  MUL    A, 10
  LD     B, [SP, 12] ; c
  ADD    C, B, 1
  ST     [SP, 12], C ; c
  LD.B   B, [B]
  SUB.B  B, '0'
  ADD    A, B
  ST     [SP, 21], A ; width
  JMP    .L402
.L403:
  LD     A, [SP, 21] ; width
  CMP    A, 0
  JNE    .L404
  LD     A, [SP, 16] ; n
  JMP    .L392
.L404:
  JMP    .L400
.L401:
  LDI    A, 1000
  ST     [SP, 21], A ; width
.L400:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CMP.B  A, 'u'
  JEQ    .L407
  CMP.B  A, 'd'
  JEQ    .L408
  CMP.B  A, 'i'
  JEQ    .L409
  CMP.B  A, 'f'
  JEQ    .L410
  CMP.B  A, 'e'
  JEQ    .L411
  CMP.B  A, 'E'
  JEQ    .L412
  CMP.B  A, 's'
  JEQ    .L413
  CMP.B  A, 'c'
  JEQ    .L414
  CMP.B  A, '%'
  JEQ    .L415
  JMP    .L406
.L407:
.L416:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JEQ    .L420
  MOV    A, 0
  JMP    .L419
.L420:
  LD     A, [SP, 8] ; ap
  ADD    B, A, 4
  ST     [SP, 8], B ; ap
  LD     A, [A]
.L419:
  LD     B, [SP, 21] ; width
  LD     C, [SP, 0] ; stream
  CALL   uscan
  CMP    A, 0
  JEQ    .L418
  LD     A, [SP, 16] ; n
  JMP    .L392
.L418:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JNE    .L421
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
.L421:
.L417:
  JMP    .L406
.L408:
.L422:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JEQ    .L426
  MOV    A, 0
  JMP    .L425
.L426:
  LD     A, [SP, 8] ; ap
  ADD    B, A, 4
  ST     [SP, 8], B ; ap
  LD     A, [A]
.L425:
  LD     B, [SP, 21] ; width
  LD     C, [SP, 0] ; stream
  CALL   dscan
  CMP    A, 0
  JEQ    .L424
  LD     A, [SP, 16] ; n
  JMP    .L392
.L424:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JNE    .L427
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
.L427:
.L423:
  JMP    .L406
.L409:
.L428:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JEQ    .L432
  MOV    A, 0
  JMP    .L431
.L432:
  LD     A, [SP, 8] ; ap
  ADD    B, A, 4
  ST     [SP, 8], B ; ap
  LD     A, [A]
.L431:
  LD     B, [SP, 21] ; width
  LD     C, [SP, 0] ; stream
  CALL   iscan
  CMP    A, 0
  JEQ    .L430
  LD     A, [SP, 16] ; n
  JMP    .L392
.L430:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JNE    .L433
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
.L433:
.L429:
  JMP    .L406
.L410:
.L434:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JEQ    .L438
  MOV    A, 0
  JMP    .L437
.L438:
  LD     A, [SP, 8] ; ap
  ADD    B, A, 4
  ST     [SP, 8], B ; ap
  LD     A, [A]
.L437:
  LD     B, [SP, 21] ; width
  LD     C, [SP, 0] ; stream
  CALL   fscan
  CMP    A, 0
  JEQ    .L436
  LD     A, [SP, 16] ; n
  JMP    .L392
.L436:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JNE    .L439
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
.L439:
.L435:
  JMP    .L406
.L411:
.L412:
.L440:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JEQ    .L444
  MOV    A, 0
  JMP    .L443
.L444:
  LD     A, [SP, 8] ; ap
  ADD    B, A, 4
  ST     [SP, 8], B ; ap
  LD     A, [A]
.L443:
  LD     B, [SP, 21] ; width
  LD     C, [SP, 0] ; stream
  CALL   escan
  CMP    A, 0
  JEQ    .L442
  LD     A, [SP, 16] ; n
  JMP    .L392
.L442:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JNE    .L445
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
.L445:
.L441:
  JMP    .L406
.L413:
.L446:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JEQ    .L450
  MOV    A, 0
  JMP    .L449
.L450:
  LD     A, [SP, 8] ; ap
  ADD    B, A, 4
  ST     [SP, 8], B ; ap
  LD     A, [A]
.L449:
  LD     B, [SP, 21] ; width
  LD     C, [SP, 0] ; stream
  CALL   sscan
  CMP    A, 0
  JEQ    .L448
  LD     A, [SP, 16] ; n
  JMP    .L392
.L448:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JNE    .L451
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
.L451:
.L447:
  JMP    .L406
.L414:
  LD.B   A, [SP, 20] ; ignore
  CMP.B  A, 0
  JEQ    .L453
  LD     A, [SP, 0] ; stream
  CALL   fgetc
  JMP    .L452
.L453:
  LD     A, [SP, 0] ; stream
  CALL   fgetc
  LD     B, [SP, 8] ; ap
  ADD    C, B, 4
  ST     [SP, 8], C ; ap
  LD     B, [B]
  ST.B   [B], A
  LD     A, [SP, 16] ; n
  ADD    A, 1
  ST     [SP, 16], A ; n
.L452:
  JMP    .L406
.L415:
  LD     A, [SP, 0] ; stream
  CALL   fgetc
  CMP.B  A, '%'
  JEQ    .L454
  LD     A, [SP, 16] ; n
  JMP    .L392
.L454:
.L406:
  JMP    .L396
.L397:
  LD     A, [SP, 12] ; c
  LD.B   A, [A]
  CALL   isspace
  CMP    A, 0
  JEQ    .L455
.L456:
  LD     A, [SP, 0] ; stream
  CALL   fgetc
  ST.B   [SP, 20], A ; peek
  CALL   isspace
  CMP    A, 0
  JEQ    .L457
  JMP    .L456
.L457:
  LD.B   A, [SP, 20] ; peek
  LD     B, [SP, 0] ; stream
  CALL   ungetc
  JMP    .L396
.L455:
  LD     A, [SP, 12] ; c
  LD.B   B, [A]
  LD     A, [SP, 0] ; stream
  CALL   fgetc
  CMP.B  B, A
  JEQ    .L396
  LD     A, [SP, 16] ; n
  JMP    .L392
.L396:
.L394:
  LD     A, [SP, 12] ; c
  ADD    A, 1
  ST     [SP, 12], A ; c
  JMP    .L393
.L395:
  LD     A, [SP, 16] ; n
.L392:
  ADD    SP, 25
  POP    PC
vscanf:
  PUSH   C, LR
  SUB    SP, 8
  ST     [SP, 0], A ; format
  ST     [SP, 4], B ; ap
  LDI    A, =stdin
  LD     A, [A]
  LD     B, [SP, 0] ; format
  LD     C, [SP, 4] ; ap
  CALL   vfscanf
.L458:
  ADD    SP, 8
  POP    C, PC
fake_read:
  SUB    SP, 8
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  MOV    A, 0
.L459:
  ADD    SP, 8
  RET
vsnscanf:
  PUSH   LR
  SUB    SP, 41
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  ST     [SP, 8], C ; format
  ST     [SP, 12], D ; ap
  ADD    A, SP, 16 ; fake
  LD     B, [SP, 0] ; s
  ST     [A, 0], B
  MOV    B, 0
  ST     [A, 4], B
  MOV    B, 0
  ST     [A, 8], B
  LD     B, [SP, 4] ; n
  ST     [A, 12], B
  MOV    B, 2
  ST.B   [A, 16], B
  LDI    B, =fake_read
  ST     [A, 17], B
  MOV    B, 0
  ST     [A, 21], B
  ADD    A, SP, 16 ; fake
  LD     B, [SP, 8] ; format
  LD     C, [SP, 12] ; ap
  CALL   vfscanf
.L460:
  ADD    SP, 41
  POP    PC
fscanf:
  PUSH   A, B, C, D
  PUSH   C, LR
  SUB    SP, 8
  ADD    A, SP, 24 ; format+1
  ST     [SP, 4], A ; ap
  LD     A, [SP, 16] ; stream
  LD     B, [SP, 20] ; format
  LD     C, [SP, 4] ; ap
  CALL   vfscanf
  ST     [SP, 0], A ; ret
  MOV    A, 0
  ST     [SP, 4], A ; ap
  LD     A, [SP, 0] ; ret
.L461:
  ADD    SP, 8
  POP    C, LR
  ADD    SP, 16
  RET
scanf:
  PUSH   A, B, C, D
  PUSH   B, C, LR
  SUB    SP, 8
  ADD    A, SP, 24 ; format+1
  ST     [SP, 4], A ; ap
  LDI    A, =stdin
  LD     A, [A]
  LD     B, [SP, 20] ; format
  LD     C, [SP, 4] ; ap
  CALL   vfscanf
  ST     [SP, 0], A ; ret
  MOV    A, 0
  ST     [SP, 4], A ; ap
  LD     A, [SP, 0] ; ret
.L462:
  ADD    SP, 8
  POP    B, C, LR
  ADD    SP, 16
  RET
snscanf:
  PUSH   A, B, C, D
  PUSH   D, LR
  SUB    SP, 8
  ADD    A, SP, 28 ; format+1
  ST     [SP, 4], A ; ap
  LD     A, [SP, 16] ; s
  LD     B, [SP, 20] ; n
  LD     C, [SP, 24] ; format
  LD     D, [SP, 4] ; ap
  CALL   vsnscanf
  ST     [SP, 0], A ; ret
  MOV    A, 0
  ST     [SP, 4], A ; ap
  LD     A, [SP, 0] ; ret
.L463:
  ADD    SP, 8
  POP    D, LR
  ADD    SP, 16
  RET
setbuf:
  SUB    SP, 8
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; buffer
  LD     A, [SP, 4] ; buffer
  CMP    A, 0
  JNE    .L464
  MOV    A, 1
  LD     B, [SP, 0] ; stream
  ST     [B, 12], A ; .capacity
.L464:
  LD     A, [SP, 4] ; buffer
  LD     B, [SP, 0] ; stream
  ST     [B, 0], A ; .base
  ADD    SP, 8
  RET
setvbuf:
  PUSH   LR
  SUB    SP, 16
  ST     [SP, 0], A ; stream
  ST     [SP, 4], B ; buffer
  ST     [SP, 8], C ; mode
  ST     [SP, 12], D ; capacity
  LD     A, [SP, 8] ; mode
  CMP    A, 1
  JEQ    .L468
  CMP    A, 0
  JEQ    .L469
  CMP    A, 2
  JEQ    .L470
  JMP    .L471
.L468:
  LD     A, [SP, 0] ; stream
  LD.B   B, [A, 16] ; .flags
  OR     B, 8
  ST.B   [A, 16], B ; .flags
.L469:
  LD     A, [SP, 12] ; capacity
  LD     B, [SP, 0] ; stream
  ST     [B, 12], A ; .capacity
  JMP    .L467
.L470:
  MOV    A, 1
  LD     B, [SP, 0] ; stream
  ST     [B, 12], A ; .capacity
  JMP    .L467
.L471:
  MOV    A, -1
  JMP    .L465
.L467:
  LD     A, [SP, 4] ; buffer
  CMP    A, 0
  JNE    .L472
  LD     A, [SP, 0] ; stream
  LD     A, [A, 12] ; .capacity
  CALL   malloc
  LD     B, [SP, 0] ; stream
  ST     [B, 0], A ; .base
  CMP    A, 0
  JNE    .L474
  MOV    A, -1
  JMP    .L465
.L474:
  LD     A, [SP, 4] ; buffer
  LD     B, [SP, 0] ; stream
  ST     [B, 0], A ; .base
.L472:
  MOV    A, 0
.L465:
  ADD    SP, 16
  POP    PC
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
.L475:
  ADD    SP, 16
  POP    C
  RET
abs:
  SUB    SP, 4
  ST     [SP, 0], A ; n
  CMP    A, 0
  JGE    .L477
  LD     A, [SP, 0] ; n
  NEG    A, A
  JMP    .L476
.L477:
  LD     A, [SP, 0] ; n
.L476:
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
.L479:
  LD     A, [SP, 16] ; low
  LD     B, [SP, 24] ; high
  CMP    A, B
  JGT    .L480
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
  JGE    .L482
  LD     A, [SP, 20] ; mid
  SUB    A, 1
  ST     [SP, 24], A ; high
  JMP    .L481
.L482:
  LD     A, [SP, 28] ; cond
  CMP    A, 0
  JLE    .L483
  LD     A, [SP, 20] ; mid
  ADD    A, 1
  ST     [SP, 16], A ; low
  JMP    .L481
.L483:
  LD     A, [SP, 20] ; mid
  LD     B, [SP, 8] ; size
  MUL    A, B
  JMP    .L478
.L481:
  JMP    .L479
.L480:
  MOV    A, -1
.L478:
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
.L484:
  LD     A, [SP, 25] ; k
  LD     B, [SP, 16] ; words
  CMP    A, B
  JCS    .L486
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
.L485:
  LD     A, [SP, 25] ; k
  ADD    A, 4
  ST     [SP, 25], A ; k
  JMP    .L484
.L486:
  MOV    A, 0
  ST.B   [SP, 29], A ; c
.L487:
  LD.B   A, [SP, 29] ; c
  LD.B   B, [SP, 20] ; tail
  CMP.B  A, B
  JGE    .L489
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
.L488:
  LD.B   A, [SP, 29] ; c
  ADD.B  A, 1
  ST.B   [SP, 29], A ; c
  JMP    .L487
.L489:
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
  JLT    .L491
  JMP    .L490
.L491:
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
.L492:
  LD     A, [SP, 16] ; i
  LD     B, [SP, 12] ; right
  CMP    A, B
  JGT    .L494
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
  JGE    .L495
  LD     A, [SP, 0] ; v
  LD     B, [SP, 4] ; size
  LD     C, [SP, 20] ; last
  ADD    C, 1
  ST     [SP, 20], C ; last
  LD     D, [SP, 16] ; i
  CALL   swap
.L495:
.L493:
  LD     A, [SP, 16] ; i
  ADD    A, 1
  ST     [SP, 16], A ; i
  JMP    .L492
.L494:
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
.L490:
  ADD    SP, 24
  POP    E, LR
  ADD    SP, 4
  RET
rand:
  PUSH   B, C
  LDI    A, =next_rand
  LD     B, [A]
  LDI    C, 1103515245
  MUL    B, C
  LDI    C, 12345
  ADD    B, C
  ST     [A], B
  LDI    A, =next_rand
  LD     A, [A]
.L496:
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
  PUSH   B, C, LR
  SUB    SP, 16
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 8], A ; i
.L498:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   A, [A, B]
  CALL   isspace
  CMP    A, 0
  JEQ    .L500
.L499:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
  JMP    .L498
.L500:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   A, [A, B]
  CMP.B  A, '-'
  JNE    .L502
  MOV    A, -1
  JMP    .L501
.L502:
  MOV    A, 1
.L501:
  ST     [SP, 4], A ; sign
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   A, [A, B]
  CMP.B  A, '-'
  JEQ    .L504
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   A, [A, B]
  CMP.B  A, '+'
  JNE    .L503
.L504:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
.L503:
  MOV    A, 0
  ST     [SP, 12], A ; n
.L505:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; i
  LD.B   A, [A, B]
  CALL   isdigit
  CMP    A, 0
  JEQ    .L507
  LD     A, [SP, 12] ; n
  MUL    A, 10
  LD     B, [SP, 0] ; s
  LD     C, [SP, 8] ; i
  LD.B   B, [B, C]
  SUB.B  B, '0'
  ADD    A, B
  ST     [SP, 12], A ; n
.L506:
  LD     A, [SP, 8] ; i
  ADD    A, 1
  ST     [SP, 8], A ; i
  JMP    .L505
.L507:
  LD     A, [SP, 4] ; sign
  LD     B, [SP, 12] ; n
  MUL    A, B
.L497:
  ADD    SP, 16
  POP    B, C, PC
atof:
  PUSH   B, C, LR
  SUB    SP, 20
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 12], A ; i
.L509:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CALL   isspace
  CMP    A, 0
  JEQ    .L511
.L510:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L509
.L511:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '-'
  JNE    .L513
  MOV    A, -1
  JMP    .L512
.L513:
  MOV    A, 1
.L512:
  ST     [SP, 16], A ; sign
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '-'
  JEQ    .L515
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '+'
  JNE    .L514
.L515:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
.L514:
  ITF    A, 0
  ST     [SP, 4], A ; f
.L516:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CALL   isdigit
  CMP    A, 0
  JEQ    .L518
  LD     A, [SP, 4] ; f
  ITF    B, 10
  MULF   A, B
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  LD.B   B, [B, C]
  SUB.B  B, '0'
  ITF    B, B
  ADDF   A, B
  ST     [SP, 4], A ; f
.L517:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L516
.L518:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '.'
  JEQ    .L519
  LD     A, [SP, 16] ; sign
  ITF    A, A
  LD     B, [SP, 4] ; f
  MULF   A, B
  JMP    .L508
.L519:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  ITF    A, 1
  ST     [SP, 8], A ; pow
.L520:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CALL   isdigit
  CMP    A, 0
  JEQ    .L522
  LD     A, [SP, 4] ; f
  ITF    B, 10
  MULF   A, B
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  LD.B   B, [B, C]
  SUB.B  B, '0'
  ITF    B, B
  ADDF   A, B
  ST     [SP, 4], A ; f
  LD     A, [SP, 8] ; pow
  ITF    B, 10
  MULF   A, B
  ST     [SP, 8], A ; pow
.L521:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L520
.L522:
  LD     A, [SP, 16] ; sign
  ITF    A, A
  LD     B, [SP, 4] ; f
  MULF   A, B
  LD     B, [SP, 8] ; pow
  DIVF   A, B
.L508:
  ADD    SP, 20
  POP    B, C, PC
getheap:
  PUSH   B, C
  SUB    SP, 8
  ST     [SP, 0], A ; n
  LDI    A, =heap
  LD     A, [A]
  ST     [SP, 4], A ; temp
  LDI    A, =heap
  LD     B, [A]
  LD     C, [SP, 0] ; n
  ADD    B, C
  ST     [A], B
  LD     A, [SP, 4] ; temp
.L523:
  ADD    SP, 8
  POP    B, C
  RET
morecore:
  PUSH   B, LR
  SUB    SP, 12
  ST     [SP, 0], A ; n
  CMP    A, 128
  JCS    .L525
  MOV    A, 128
  ST     [SP, 0], A ; n
.L525:
  LD     A, [SP, 0] ; n
  CALL   getheap
  ST     [SP, 8], A ; header
  LD     A, [SP, 0] ; n
  LD     B, [SP, 8] ; header
  ST     [B, 4], A ; .size
  LD     A, [SP, 8] ; header
  ADD    A, 8 ; +1
  CALL   free
  LDI    A, =freehead
  LD     A, [A]
.L524:
  ADD    SP, 12
  POP    B, PC
malloc:
  PUSH   B, C, LR
  SUB    SP, 16
  ST     [SP, 0], A ; bytes
  ADD    A, 8
  ST     [SP, 12], A ; units
  LDI    A, =freehead
  LD     A, [A]
  ST     [SP, 8], A ; prevp
  CMP    A, 0
  JNE    .L527
  LDI    A, =base
  ST     [SP, 8], A ; prevp
  LDI    B, =freehead
  ST     [B], A
  LDI    B, =base
  ST     [B, 0], A ; .next
  MOV    A, 0
  LDI    B, =base
  ST     [B, 4], A ; .size
.L527:
  LD     A, [SP, 8] ; prevp
  LD     A, [A, 0] ; .next
  ST     [SP, 4], A ; p
.L528:
  LD     A, [SP, 4] ; p
  LD     A, [A, 4] ; .size
  LD     B, [SP, 12] ; units
  CMP    A, B
  JNE    .L531
  LD     A, [SP, 4] ; p
  LD     A, [A, 0] ; .next
  LD     B, [SP, 8] ; prevp
  ST     [B, 0], A ; .next
  LD     A, [SP, 8] ; prevp
  LDI    B, =freehead
  ST     [B], A
  LD     A, [SP, 4] ; p
  ADD    A, 8 ; +1
  JMP    .L526
.L531:
  LD     A, [SP, 4] ; p
  LD     A, [A, 4] ; .size
  LD     B, [SP, 12] ; units
  ADD    B, 8
  CMP    A, B
  JLS    .L532
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
  LD     A, [SP, 8] ; prevp
  LDI    B, =freehead
  ST     [B], A
  LD     A, [SP, 4] ; p
  ADD    A, 8 ; +1
  JMP    .L526
.L532:
  LD     A, [SP, 4] ; p
  LDI    B, =freehead
  LD     B, [B]
  CMP    A, B
  JNE    .L533
  LD     A, [SP, 12] ; units
  CALL   morecore
  ST     [SP, 4], A ; p
  CMP    A, 0
  JNE    .L534
  MOV    A, 0
  JMP    .L526
.L534:
.L533:
.L529:
  LD     A, [SP, 4] ; p
  ST     [SP, 8], A ; prevp
  LD     A, [SP, 4] ; p
  LD     A, [A, 0] ; .next
  ST     [SP, 4], A ; p
  JMP    .L528
.L530:
.L526:
  ADD    SP, 16
  POP    B, C, PC
free:
  PUSH   B, C
  SUB    SP, 12
  ST     [SP, 0], A ; original
  CMP    A, 0
  JEQ    .L535
  LD     A, [SP, 0] ; original
  SUB    A, 8
  ST     [SP, 4], A ; free
  LDI    A, =freehead
  LD     A, [A]
  ST     [SP, 8], A ; p
.L536:
  LD     A, [SP, 8] ; p
  LD     B, [SP, 4] ; free
  CMP    A, B
  JCS    .L539
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  LD     B, [B, 0] ; .next
  CMP    A, B
  JCC    .L538
.L539:
  LD     A, [SP, 8] ; p
  LD     B, [A, 0] ; .next
  CMP    A, B
  JCC    .L540
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  CMP    A, B
  JHI    .L541
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  LD     B, [B, 0] ; .next
  CMP    A, B
  JCS    .L540
.L541:
  JMP    .L538
.L540:
.L537:
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  ST     [SP, 8], A ; p
  JMP    .L536
.L538:
  LD     A, [SP, 4] ; free
  LD     B, [A, 4] ; .size
  ADD    A, B
  LD     B, [SP, 8] ; p
  LD     B, [B, 0] ; .next
  CMP    A, B
  JNE    .L543
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
  JMP    .L542
.L543:
  LD     A, [SP, 8] ; p
  LD     A, [A, 0] ; .next
  LD     B, [SP, 4] ; free
  ST     [B, 0], A ; .next
.L542:
  LD     A, [SP, 8] ; p
  LD     B, [A, 4] ; .size
  ADD    A, B
  LD     B, [SP, 4] ; free
  CMP    A, B
  JNE    .L545
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
  JMP    .L544
.L545:
  LD     A, [SP, 4] ; free
  LD     B, [SP, 8] ; p
  ST     [B, 0], A ; .next
.L544:
  LD     A, [SP, 8] ; p
  LDI    B, =freehead
  ST     [B], A
.L535:
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
.L546:
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
.L548:
  LD     A, [SP, 20] ; i
  LD     B, [SP, 12] ; words
  CMP    A, B
  JCS    .L550
  MOV    A, 0
  LD     B, [SP, 24] ; p
  LD     C, [SP, 20] ; i
  ADD    B, C
  ST     [B], A
.L549:
  LD     A, [SP, 20] ; i
  ADD    A, 1
  ST     [SP, 20], A ; i
  JMP    .L548
.L550:
  MOV    A, 0
  ST     [SP, 28], A ; c
.L551:
  LD     A, [SP, 28] ; c
  LD     B, [SP, 16] ; tail
  CMP    A, B
  JCS    .L553
  MOV    A, 0
  LD     B, [SP, 24] ; p
  LD     C, [SP, 20] ; i
  ADD    B, C
  LD     C, [SP, 28] ; c
  ADD    B, C
  ST.B   [B], A
.L552:
  LD     A, [SP, 28] ; c
  ADD    A, 1
  ST     [SP, 28], A ; c
  JMP    .L551
.L553:
  LD     A, [SP, 24] ; p
.L547:
  ADD    SP, 32
  POP    C, PC
strlen:
  PUSH   B
  SUB    SP, 8
  ST     [SP, 0], A ; s
  MOV    A, 0
  ST     [SP, 4], A ; l
.L555:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; l
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JEQ    .L556
  LD     A, [SP, 4] ; l
  ADD    A, 1
  ST     [SP, 4], A ; l
  JMP    .L555
.L556:
  LD     A, [SP, 4] ; l
.L554:
  ADD    SP, 8
  POP    B
  RET
strnlen:
  SUB    SP, 12
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  MOV    A, 0
  ST     [SP, 8], A ; l
.L558:
  LD     A, [SP, 8] ; l
  LD     B, [SP, 4] ; n
  CMP    A, B
  JCS    .L559
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; l
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JEQ    .L559
  LD     A, [SP, 8] ; l
  ADD    A, 1
  ST     [SP, 8], A ; l
  JMP    .L558
.L559:
  LD     A, [SP, 8] ; l
.L557:
  ADD    SP, 12
  RET
strcpy:
  PUSH   C, D, LR
  SUB    SP, 8
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  LD     D, [SP, 0] ; s
  LD     B, [SP, 4] ; t
  MOV    A, B
  CALL   strlen
  ADD    C, A, 1
  MOV    A, D
  CALL   strncpy
.L560:
  ADD    SP, 8
  POP    C, D, PC
strncpy:
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  MOV    A, 0
  ST     [SP, 12], A ; i
.L562:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  SUB    B, 1
  CMP    A, B
  JCS    .L564
  LD     B, [SP, 4] ; t
  LD     A, [SP, 12] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 0] ; s
  ST.B   [C, A], B
  CMP.B  B, '\0'
  JEQ    .L564
.L563:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L562
.L564:
  MOV.B  A, '\0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ST.B   [B, C], A
  LD     A, [SP, 0] ; s
.L561:
  ADD    SP, 16
  RET
strdup:
  PUSH   B, C, LR
  SUB    SP, 4
  ST     [SP, 0], A ; s
  LD     C, [SP, 0] ; s
  MOV    A, C
  CALL   strlen
  ADD    B, A, 1
  MOV    A, C
  CALL   strndup
.L565:
  ADD    SP, 4
  POP    B, C, PC
strndup:
  PUSH   C, LR
  SUB    SP, 12
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  LD     A, [SP, 4] ; n
  CALL   malloc
  ST     [SP, 8], A ; p
  CMP    A, 0
  JEQ    .L567
  LD     A, [SP, 8] ; p
  LD     B, [SP, 0] ; s
  LD     C, [SP, 4] ; n
  CALL   strncpy
.L567:
  LD     A, [SP, 8] ; p
.L566:
  ADD    SP, 12
  POP    C, PC
strcat:
  PUSH   C, D, LR
  SUB    SP, 8
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  LD     D, [SP, 0] ; s
  LD     B, [SP, 4] ; t
  MOV    A, D
  CALL   strlen
  MOV    C, A
  LD     A, [SP, 4] ; t
  CALL   strlen
  ADD    A, C, A
  ADD    C, A, 1
  MOV    A, D
  CALL   strncat
.L568:
  ADD    SP, 8
  POP    C, D, PC
strncat:
  PUSH   D, LR
  SUB    SP, 20
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  LD     A, [SP, 8] ; n
  CMP    A, 0
  JNE    .L570
  LD     A, [SP, 0] ; s
  JMP    .L569
.L570:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; n
  CALL   strnlen
  ST     [SP, 12], A ; i
  MOV    A, 0
  ST     [SP, 16], A ; j
.L571:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  SUB    B, 1
  CMP    A, B
  JCS    .L572
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
  JEQ    .L572
  JMP    .L571
.L572:
  MOV.B  A, '\0'
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; i
  ST.B   [B, C], A
  LD     A, [SP, 0] ; s
.L569:
  ADD    SP, 20
  POP    D, PC
strrev:
  PUSH   B, C, LR
  SUB    SP, 4
  ST     [SP, 0], A ; s
  LD     C, [SP, 0] ; s
  MOV    A, C
  CALL   strlen
  ADD    B, A, 1
  MOV    A, C
  CALL   strnrev
.L573:
  ADD    SP, 4
  POP    B, C, PC
strnrev:
  PUSH   C, LR
  SUB    SP, 17
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; n
  MOV    A, 0
  ST     [SP, 8], A ; front
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; n
  CALL   strnlen
  SUB    A, 1
  ST     [SP, 12], A ; back
.L575:
  LD     A, [SP, 8] ; front
  LD     B, [SP, 12] ; back
  CMP    A, B
  JCS    .L577
  LD     A, [SP, 0] ; s
  LD     B, [SP, 8] ; front
  LD.B   A, [A, B]
  ST.B   [SP, 16], A ; temp
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; back
  LD.B   B, [A, B]
  LD     C, [SP, 8] ; front
  ST.B   [A, C], B
  LD.B   A, [SP, 16] ; temp
  LD     B, [SP, 0] ; s
  LD     C, [SP, 12] ; back
  ST.B   [B, C], A
.L576:
  LD     A, [SP, 8] ; front
  ADD    A, 1
  ST     [SP, 8], A ; front
  LD     A, [SP, 12] ; back
  SUB    A, 1
  ST     [SP, 12], A ; back
  JMP    .L575
.L577:
  LD     A, [SP, 0] ; s
.L574:
  ADD    SP, 17
  POP    C, PC
strcmp:
  PUSH   C, D, LR
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  LD     A, [SP, 0] ; s
  CALL   strlen
  ST     [SP, 8], A ; l
  LD     A, [SP, 4] ; t
  CALL   strlen
  ST     [SP, 12], A ; m
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; t
  LD     C, [SP, 8] ; l
  LD     D, [SP, 12] ; m
  CMP    C, D
  JLS    .L580
  LD     C, [SP, 8] ; l
  JMP    .L579
.L580:
  LD     C, [SP, 12] ; m
.L579:
  CALL   strncmp
.L578:
  ADD    SP, 16
  POP    C, D, PC
strncmp:
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  MOV    A, 0
  ST     [SP, 12], A ; i
.L582:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L584
  LD     B, [SP, 0] ; s
  LD     A, [SP, 12] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 4] ; t
  LD.B   A, [C, A]
  CMP.B  B, A
  JNE    .L584
  LD     A, [SP, 0] ; s
  LD     B, [SP, 12] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JNE    .L585
  MOV    A, 0
  JMP    .L581
.L585:
.L583:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L582
.L584:
  LD     B, [SP, 0] ; s
  LD     A, [SP, 12] ; i
  LD.B   B, [B, A]
  LD     C, [SP, 4] ; t
  LD.B   A, [C, A]
  SUB.B  A, B, A
.L581:
  ADD    SP, 16
  RET
strchr:
  SUB    SP, 9
  ST     [SP, 0], A ; s
  ST.B   [SP, 4], B ; c
  MOV    A, 0
  ST     [SP, 5], A ; i
.L587:
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  LD.B   A, [A, B]
  CMP.B  A, '\0'
  JEQ    .L589
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  LD.B   A, [A, B]
  LD.B   B, [SP, 4] ; c
  CMP.B  A, B
  JNE    .L590
  LD     A, [SP, 0] ; s
  LD     B, [SP, 5] ; i
  ADD    A, B
  JMP    .L586
.L590:
.L588:
  LD     A, [SP, 5] ; i
  ADD    A, 1
  ST     [SP, 5], A ; i
  JMP    .L587
.L589:
  MOV    A, 0
.L586:
  ADD    SP, 9
  RET
memset:
  SUB    SP, 13
  ST     [SP, 0], A ; s
  ST.B   [SP, 4], B ; v
  ST     [SP, 5], C ; n
  MOV    A, 0
  ST     [SP, 9], A ; i
.L592:
  LD     A, [SP, 9] ; i
  LD     B, [SP, 5] ; n
  CMP    A, B
  JCS    .L594
  LD.B   A, [SP, 4] ; v
  LD     B, [SP, 0] ; s
  LD     C, [SP, 9] ; i
  ADD    B, C
  ST.B   [B], A
.L593:
  LD     A, [SP, 9] ; i
  ADD    A, 1
  ST     [SP, 9], A ; i
  JMP    .L592
.L594:
  LD     A, [SP, 0] ; s
.L591:
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
.L596:
  LD     A, [SP, 17] ; i
  LD     B, [SP, 12] ; words
  CMP    A, B
  JCS    .L598
  LD     B, [SP, 4] ; t
  LD     A, [SP, 17] ; i
  SHL    A, 2
  ADD    B, A
  LD     B, [B]
  LD     C, [SP, 0] ; s
  ADD    A, C, A
  ST     [A], B
.L597:
  LD     A, [SP, 17] ; i
  ADD    A, 1
  ST     [SP, 17], A ; i
  JMP    .L596
.L598:
  MOV    A, 0
  ST.B   [SP, 21], A ; c
.L599:
  LD.B   A, [SP, 21] ; c
  LD.B   B, [SP, 16] ; tail
  CMP.B  A, B
  JGE    .L601
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
.L600:
  LD.B   A, [SP, 21] ; c
  ADD.B  A, 1
  ST.B   [SP, 21], A ; c
  JMP    .L599
.L601:
  LD     A, [SP, 0] ; s
.L595:
  ADD    SP, 22
  POP    D
  RET
memmove:
  PUSH   LR
  SUB    SP, 12
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  LD     A, [SP, 0] ; s
  LD     B, [SP, 4] ; t
  LD     C, [SP, 8] ; n
  CALL   memcpy
.L602:
  ADD    SP, 12
  POP    PC
memcmp:
  SUB    SP, 16
  ST     [SP, 0], A ; s
  ST     [SP, 4], B ; t
  ST     [SP, 8], C ; n
  MOV    A, 0
  ST     [SP, 12], A ; i
.L604:
  LD     A, [SP, 12] ; i
  LD     B, [SP, 8] ; n
  CMP    A, B
  JCS    .L606
  LD     B, [SP, 0] ; s
  LD     A, [SP, 12] ; i
  ADD    B, A
  LD.B   B, [B]
  LD     C, [SP, 4] ; t
  ADD    A, C, A
  LD.B   A, [A]
  CMP.B  B, A
  JEQ    .L607
  LD     B, [SP, 0] ; s
  LD     A, [SP, 12] ; i
  ADD    B, A
  LD.B   B, [B]
  LD     C, [SP, 4] ; t
  ADD    A, C, A
  LD.B   A, [A]
  SUB.B  A, B, A
  JMP    .L603
.L607:
.L605:
  LD     A, [SP, 12] ; i
  ADD    A, 1
  ST     [SP, 12], A ; i
  JMP    .L604
.L606:
  MOV    A, 0
.L603:
  ADD    SP, 16
  RET