STACK_INIT = 0x00800000
OUT = 0x80000000
IN = 0x80000001

.boot:
    NOP
    MOV SP, STACK_INIT
    CALL main
    HALT

; char in();
in:
    MOV A, IN
    LD.B A, [A]
    RET

; void out(char);
out:
    PUSH B
    MOV B, OUT
    ST.B [B], A
    POP B
    RET

.interrupt:
    OR SR, 0b00100000 ; disable interrupts
    PUSH LR, SR
    CALL interrupt
    POP LR, SR
    AND SR, 0b11011111 ; enable interrupts
    IRET


stdin:  .word _stdin

stdout: .word _stdout

stderr: .word _stderr

errno:  .word 0

heap: .word .heap_start

; int setjmp(jmp_buf);
setjmp:
    ; ST [A, 0], A ; Not needed
    ST [A, 4], B
    ST [A, 8], C
    ST [A, 12], D
    ST [A, 16], E
    ST [A, 20], F
    ST [A, 24], G
    ST [A, 28], H
    ST [A, 32], I
    ST [A, 36], J
    ST [A, 40], K
    ST [A, 44], SP
    ST [A, 48], SR
    ST [A, 52], ILR
    ST [A, 56], LR
    ; ST [A, 60], PC ; not needed
    MOV A, 0
    RET

; void longjmp(jmp_buf, int);
longjmp:
    ST [A, 0], B
    LD B, [A, 4]
    LD C, [A, 8]
    LD D, [A, 12]
    LD E, [A, 16]
    LD F, [A, 20]
    LD G, [A, 24]
    LD H, [A, 28]
    LD I, [A, 32]
    LD J, [A, 36]
    LD K, [A, 40]
    LD SP, [A, 44]
    LD SR, [A, 48]
    LD ILR, [A, 52]
    LD LR, [A, 56]
    ; LD PC, [A, 60] ; Not needed
    LD A, [A, 0]
    RET

abort:
    HALT
