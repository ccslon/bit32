#define HANDLE(action) (void handle#action() {})
HANDLE(JUMP)
HANDLE(LEFT)
HANDLE(RIGHT)
HANDLE(FRONT)
HANDLE(BACK)
enum Action {
    LEFT,
    RIGHT,
    JUMP,
    FRONT,
    BACK
};

void error(char);

void do_action(enum Action action) {
    switch (action) {
        case FRONT:
            handleFRONT();
            break;
        case BACK:
            handleBACK();
            break;
        case LEFT:
            handleLEFT();
            break;
        case RIGHT:
            handleLEFT();
            break;
        default:
            error("WHOA!\n");
    }
}

/*
L0:
    .L1
    .L2
    
    .L3
    .L4


*/