STACK_INIT = 0x8000
boot:
    NOP
    MOV SP, STACK_INIT
    CALL main
    HALT