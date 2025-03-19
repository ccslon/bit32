while_loop:
  PUSH A, LR
.L0:
  CALL foo
  CMP A, 0
  JEQ .L1
  CALL bar
  CMP A, 0
  JEQ .L3
  JMP .L0
  JMP .L2
.L3:
  JMP .L1
.L2:
  JMP .L0
.L1:
  POP A, PC
for_loop:
  PUSH A, B, LR
  SUB SP, 4
  MOV A, 0
  ST [SP, 0], A ; i
.L4:
  CALL foo
  CMP A, 0
  JEQ .L6
  CALL bar
  CMP A, 0
  JEQ .L8
  JMP .L5
  JMP .L7
.L8:
  JMP .L6
.L7:
.L5:
  LD A, [SP, 0] ; i
  ADD B, A, 1
  ST [SP, 0], B ; i
  JMP .L4
.L6:
  ADD SP, 4
  POP A, B, PC