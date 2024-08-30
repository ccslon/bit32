STACK_INIT = 0x7ffffc
boot:
    NOP
    MOV SP, STACK_INIT
    CALL main
    HALT