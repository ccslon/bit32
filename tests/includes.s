foo: .word 9
test:
  PUSH   A
  SUB    SP, 4
  MOV    A, 10
  MUL    A, 100
  ST     [SP, 0], A ; num
  ADD    SP, 4
  POP    A
  RET