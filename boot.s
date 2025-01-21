STACK_INIT = 0x7ffffc
STDOUT = 0x80000000
STDIN = 0x80000001
.boot:
    NOP
    MOV SP, STACK_INIT
    CALL main
    HALT
; char in();
in:
    PUSH B
    MOV B, STDIN
    LD.B A, [B]
    POP B
    RET
; void out(char);
out:
    PUSH B
    MOV B, STDOUT
    ST.B [B], A
    POP B
    RET
interrupt_handler:
    OR SR, 0b00100000 ; disable interrupts
    PUSH LR, A, B, C, D, SR, FP
    SUB SP, 1
    MOV FP, SP
    MOV.B A, 0
    ST.B [FP, 0], A
.i0:
    LD.B A, [FP, 0]
    CMP.B A, 8
    JGE .i1
    CALL in
    CMP.B A, '\0'
    JEQ .i1
    CALL out
    LDI B, =.stdin
    LDI C, =stdin_write
    CMP.B A, '\n'
    JEQ .i2
    CMP.B A, '\b'
    JEQ .i3
    JMP .i5
.i2: ; '\n'
    MOV A, '\0'    
    JMP .i5
.i3: ; '\b'
    LD A, [C]
    CMP A, 0
    JNE .i4
    SUB A, 1
    ST [C], A
    JMP .i6
.i4:
    MOV A, 31
    ST [C], A
    JMP .i6
.i5:
    LD D, [C]
    ST [B, D], A
    ADD D, 1
    MOD D, 32
    ST [C], D
.i6:
    LD A, [FP, 0]
    ADD A, 1
    ST [FP, 0], A
    JMP .i0
.i1:
    MOV SP, FP
    ADD SP, 1
    POP LR, A, B, C, D, SR, FP
    AND SR, 0b11011111 ; enable interrupts
    IRET

.stdin:         .space 32
stdin:          .word .stdin
stdin_read:     .word 0
stdin_write:    .word 0
stdin_size:     .word 32
stdout:
                .word STDOUT ; buffer
                .word 0      ; read
                .word 0      ; write
                .word 1      ; size
errno: .byte 0
crash:
    HALT