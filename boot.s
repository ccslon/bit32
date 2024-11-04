STACK_INIT = 0x7ffffc
boot:
    NOP
    MOV SP, STACK_INIT
    CALL main
    HALT
in:
    PUSH B
    LDI B, 0x80000001
    LD.B A, [B]
    POP B
    RET
out:
    PUSH B
    LDI B, 0x80000000
    ST.B [B], A
    POP B
    RET