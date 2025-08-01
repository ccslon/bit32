add:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  ADD    A, B
  CMP    A, 0
.L1:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  ADD    A, B
.L0:
  ADD    SP, 8
  RET
sub:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  SUB    A, B
  CMP    A, 0
.L3:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  SUB    A, B
.L2:
  ADD    SP, 8
  RET
mul:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  MUL    A, B
  CMP    A, 0
.L5:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  MUL    A, B
.L4:
  ADD    SP, 8
  RET
div:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  DIV    A, B
  CMP    A, 0
.L7:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  DIV    A, B
.L6:
  ADD    SP, 8
  RET
mod:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  MOD    A, B
  CMP    A, 0
.L9:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  MOD    A, B
.L8:
  ADD    SP, 8
  RET
shl:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  SHL    A, B
  CMP    A, 0
.L11:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  SHL    A, B
.L10:
  ADD    SP, 8
  RET
shr:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  SHR    A, B
  CMP    A, 0
.L13:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  SHR    A, B
.L12:
  ADD    SP, 8
  RET
eq:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
.L15:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
  MOVEQ  A, 1
  MOVNE  A, 0
.L14:
  ADD    SP, 8
  RET
ne:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
.L17:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
  MOVNE  A, 1
  MOVEQ  A, 0
.L16:
  ADD    SP, 8
  RET
le:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
.L19:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
  MOVLE  A, 1
  MOVGT  A, 0
.L18:
  ADD    SP, 8
  RET
ge:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
.L21:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
  MOVGE  A, 1
  MOVLT  A, 0
.L20:
  ADD    SP, 8
  RET
lt:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
.L23:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
  MOVLT  A, 1
  MOVGE  A, 0
.L22:
  ADD    SP, 8
  RET
gt:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
.L25:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  CMP    A, B
  MOVGT  A, 1
  MOVLE  A, 0
.L24:
  ADD    SP, 8
  RET
and:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  AND    A, B
  CMP    A, 0
.L27:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  AND    A, B
.L26:
  ADD    SP, 8
  RET
xor:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  XOR    A, B
  CMP    A, 0
.L29:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  XOR    A, B
.L28:
  ADD    SP, 8
  RET
or:
  SUB    SP, 8
  ST     [SP, 0], A ; l
  ST     [SP, 4], B ; r
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  OR     A, B
  CMP    A, 0
.L31:
  LD     A, [SP, 0] ; l
  LD     B, [SP, 4] ; r
  OR     A, B
.L30:
  ADD    SP, 8
  RET
not:
  SUB    SP, 4
  ST     [SP, 0], A ; a
  LD     A, [SP, 0] ; a
  CMP    A, 0
.L33:
  LD     A, [SP, 0] ; a
  CMP    A, 0
  MOVEQ  A, 1
  MOVNE  A, 0
.L32:
  ADD    SP, 4
  RET