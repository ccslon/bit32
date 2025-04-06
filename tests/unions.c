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
    printf("%u\n", ip.i);
}
enum Type {
    CHAR,
    NUM,
    STR
};
struct Token {
    enum Type type;
    union {
        char* str;
        int num;
        char sym;
    };
};
struct Token intToken(int num) {
    struct Token token;
    token.type = NUM;
    token.num = num;
    return token;
}
struct Token strToken(char* str) {
    struct Token token;
    token.type = STR;
    token.str = str;
    return token;
}
struct Token charToken(char c) {
    struct Token token;
    token.type = CHAR;
    token.sym = c;
    return token;
}
void printToken(struct Token* token) {
    switch (token->type) {
        case STR: {
            printf("(STR, \"%s\")", token->str);
            break;
        }
        case NUM: {
            printf("(NUM, %d)", token->num);
            break;
        }
        case CHAR: {
            printf("(CHAR, '%c')", token->sym);
        }
    }
}
int main() {
	struct Token t0 = charToken('c');
    printToken(&t0);
    struct Token t1 = intToken(5);
    printToken(&t1);
    struct Token t2 = strToken("Hello!");
    printToken(&t2);
}
union Box {
    short num;
};
short gets(short* s) {
    return *s;
}
short gets(union Box* s) {
    return s->num;
}
short gets() {
    short s;
    return s;
}
short gets() {
    union Box box;
    return box.num;
}
short geta() {
    short foo[5];
    return foo[3];
}
short geta() {
    union Box boxes[5];
    return boxes[3].num;
}
short geta() {
    short* foo[5];
    return *foo[3];
}
short geta() {
    union Box* boxes[5];
    return boxes[3]->num;
}