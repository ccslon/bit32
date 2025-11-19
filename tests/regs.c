int sum(int* arr, int n) {
    int sum = 0;
    register int i;
    for (i = 0; i < n; i++) {
        sum += arr[i];
    }
    return sum;
}

/*
sum:
  PUSH   C
  SUB    SP, 16
  ST     [SP, 0], A ; arr
  ST     [SP, 4], B ; n
  MOV    A, 0
  ST     [SP, 8], A ; sum
  MOV    A, 0 ; i
.L1:
  LD     B, [SP, 4] ; n
  CMP    A, B
  JGE    .L3
  LD     B, [SP, 8] ; sum
  LD     C, [SP, 0] ; arr
  SHL    A, 2
  LD     D, [C, A]
  ADD    B, D
  ST     [SP, 8], B ; sum
.L2:
  LD     A, [SP, 12] ; i
  ADD    B, A, 1
  ST     [SP, 12], B ; i
  JMP    .L1
.L3:
  LD     B, [SP, 8] ; sum
.L0:
  MOV    A, B
  ADD    SP, 16
  POP    C
  RET
*/