.S0: "Hello world!\n\0"
main:
  PUSH A, LR
  LDI A, =.S0
  CALL printf
  POP A, PC