div:
  SUB SP, 16
  ST [SP, 0], A
  ST [SP, 4], B
  MOV A, 3
  ADD B, SP, 8
  ST [B, 0], A ; quot
  MOV A, 4
  ADD B, SP, 8
  ST [B, 4], A ; rem
  ADD A, SP, 8
  JMP .L0
.L0:
  ADD SP, 16
  RET
print_int:
  PUSH B, C, LR
  SUB SP, 12
  ST [SP, 0], A
  LD A, [SP, 0] ; num
  MOV B, 10
  CALL div
  ADD B, SP, 4
  LD C, [A, 0]
  ST [B, 0], C
  LD C, [A, 4]
  ST [B, 4], C
  ADD SP, 12
  POP B, C, PC