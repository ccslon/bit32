#define HANDLE(action) void handle##action() {}
HANDLE(JUMP)
HANDLE(LEFT)
HANDLE(RIGHT)
HANDLE(FRONT)
HANDLE(BACK)
enum Action {
    LEFT,   //0
    RIGHT,  //1
    JUMP,   //2
    FRONT,  //3
    BACK    //4
};

void error(char*);

void do_action(enum Action action) {
    switch (action) {
        case FRONT: // 3
            handleFRONT();
            break;
        case BACK: // 4
            handleBACK();
            break;
        case LEFT: // 0
            handleLEFT();
            break;
        case RIGHT: //1
            handleRIGHT();
            break;
        default:
            error("WHOA!\n");
    }
}

char test_char(char c) {
    switch (c) {
        case 'a':
        case 'b':
        case 'c':
            return c + 1;
        case 'i':
        case 'j':
        case 'k':
            return c + 5;
        default:
            return c - 'a' + 'A';
    }
}