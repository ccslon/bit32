myfloat: .word 1069547520
foo:
  SUB    SP, 8
  ST     [SP, 0], A ; a
  ST     [SP, 4], B ; b
  LD     A, [SP, 0] ; a
  LD     B, [SP, 4] ; b
  ADDF   A, B
.L0:
  ADD    SP, 8
  RET
func1:
  PUSH   A, B, LR
  SUB    SP, 4
  LDI    A, 1069547520 ; 1.5
  ST     [SP, 0], A ; f
  LD     A, [SP, 0] ; f
  LDI    B, 3217031168 ; -1.5
  CALL   foo
  ADD    SP, 4
  POP    A, B, PC
half1:
  MOV    A, 0
.L1:
  RET
half2:
  LDI    A, 1056964608 ; 0.5
.L2:
  RET
half3:
  LDI    A, 1056964608 ; 0.5
.L3:
  RET
test:
  SUB    SP, 24
  ST     [SP, 0], A ; i
  ST     [SP, 4], B ; f
  LD     A, [SP, 0] ; i
  SHR    A, 1
  ST     [SP, 8], A ; half1
  LD     A, [SP, 0] ; i
  ITF    A, A
  LDI    B, 1073741824 ; 2.0
  DIVF   A, B
  FTI    A, A
  ST     [SP, 12], A ; half2
  LD     A, [SP, 4] ; f
  ITF    B, 2
  DIVF   A, B
  ST     [SP, 16], A ; half3
  LD     A, [SP, 4] ; f
  LDI    B, 1073741824 ; 2.0
  DIVF   A, B
  ST     [SP, 20], A ; half4
  ADD    SP, 24
  RET
func2:
  PUSH   A, B
  SUB    SP, 16
  LDI    A, 1069547520 ; 1.5
  FTI    A, A
  ST     [SP, 4], A ; foo
  LD     A, [SP, 0] ; foo
  FTI    A, A
  ST     [SP, 8], A ; i
  LD     A, [SP, 4] ; foo
  ITF    A, A
  LD     B, [SP, 0] ; foo
  ADDF   A, B
  FTI    A, A
  ST     [SP, 12], A ; x
  ADD    SP, 16
  POP    A, B
  RET