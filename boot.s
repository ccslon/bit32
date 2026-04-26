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
STDIN_BUFFER_SIZE = 32
interrupt_handler:
    OR SR, 0b00100000 ; disable interrupts
    PUSH LR, A, B, C, D, SR
    SUB SP, 1
    MOV.B A, 0
    ST.B [SP, 0], A
    LDI B, =.stdin_buf
    LDI C, =.stdin_write
.loop_head:
    LD.B A, [SP, 0]
    CMP.B A, 8
    JGE .interrupt_end
    CALL in
    CMP.B A, '\0'
    JEQ .interrupt_end
    CALL out
    LD D, [C]
    ST.B [B, D], A
    ADD D, 1
    AND D, STDIN_BUFFER_SIZE - 1
    ST [C], D
.loop_tail:
    LD.B A, [SP, 0]
    ADD.B A, 1
    ST.B [SP, 0], A
    JMP .loop_head
.interrupt_end:
    ADD SP, 1
    POP LR, A, B, C, D, SR
    AND SR, 0b11011111 ; enable interrupts
    IRET

.stdin_buf:     .space STDIN_BUFFER_SIZE
.stdin:         .word .stdin_buf
.stdin_read:    .word 0
.stdin_write:   .word 0
.stdin_size:    .word STDIN_BUFFER_SIZE
.stdout:
                .word OUT ; buffer
                .word 0      ; read
                .word 0      ; write
                .word 1      ; size

stdin:  .word .stdin
stdout: .word .stdout

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

.heap: .word .heap_start
; void* morecore(int);
getheap:
    PUSH B, C, D
    LDI B, =.heap
    LD C, [B]
    ADD D, A, C
    ST [B], D
    MOV A, C
    POP B, C, D
    RET

abort:
    HALT