void printf(char*, ...);
union IP {
    unsigned int i;
    unsigned char c[4];
};
void func1() {
    union IP ip;
    ip.c[0] = 127;
    ip.c[1] = 0;
    ip.c[2] = 0;
    ip.c[3] = 1;
    int i = ip.i;
}
enum Type {
    CHAR,
    NUM,
    STR
};
struct Token {
    enum Type type;
    union Data {
        char* str;
        int num;
        char chr;
    } data;
};
struct Token intToken(int num) {
    struct Token token;
    token.type = NUM;
    token.data.num = num;
    return token;
}
struct Token strToken(char* str) {
    struct Token token;
    token.type = STR;
    token.data.str = str;
    return token;
}
struct Token charToken(char c) {
    struct Token token;
    token.type = CHAR;
    token.data.chr = c;
    return token;
}
void printToken(struct Token* token) {
    switch (token->type) {
        case STR: {
            printf("(STR, '%s')", token->data.str);
            break;
        }
        case NUM: {
            printf("(NUM, %d)", token->data.num);
            break;
        }
        case CHAR: {
            printf("(CHAR, '%c')", token->data.chr);
        }
    }
}
int main() {
    struct Token t1 = intToken(5);
    printToken(&t1);
    struct Token t2 = strToken("Hello!");
    printToken(&t2);
}