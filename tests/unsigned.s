foo:
  SUB SP, 32
  ST [SP, 0], A
  ST [SP, 4], B
  LD A, [SP, 0] ; u
  LD B, [SP, 4] ; i
  CMP A, B
  MOVEQ A, 1
  MOVNE A, 0
  ST [SP, 8], A ; a
  LD A, [SP, 0] ; u
  LD B, [SP, 4] ; i
  CMP A, B
  MOVNE A, 1
  MOVEQ A, 0
  ST [SP, 12], A ; b
  LD A, [SP, 0] ; u
  LD B, [SP, 4] ; i
  CMP A, B
  MOVHI A, 1
  MOVLS A, 0
  ST [SP, 16], A ; c
  LD A, [SP, 0] ; u
  LD B, [SP, 4] ; i
  CMP A, B
  MOVCC A, 1
  MOVCS A, 0
  ST [SP, 20], A ; d
  LD A, [SP, 0] ; u
  LD B, [SP, 4] ; i
  CMP A, B
  MOVCS A, 1
  MOVCC A, 0
  ST [SP, 24], A ; e
  LD A, [SP, 0] ; u
  LD B, [SP, 4] ; i
  CMP A, B
  MOVLS A, 1
  MOVHI A, 0
  ST [SP, 28], A ; f
.L0:
  ADD SP, 32
  RET