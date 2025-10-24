foo: .word 9
test:
  PUSH   A
  SUB    SP, 4
  LDI    A, 1000
  ST     [SP, 0], A ; num
  ADD    SP, 4
  POP    A
  RET