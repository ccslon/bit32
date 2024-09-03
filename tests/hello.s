.S0: "Hello world!\n\0"
main:
  PUSH LR, A, B, FP
  MOV FP, SP
  LD B, =.S0
  MOV A, B
  CALL printf
  MOV SP, FP
  POP PC, A, B, FP