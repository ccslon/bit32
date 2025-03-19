main:
  SUB SP, 5
  MOV A, 10
  ST.B [SP, 0], A ; day
  MOV A, 4
  ST [SP, 1], A ; today
  MOV A, 0
  JMP .L0
.L0:
  ADD SP, 5
  RET