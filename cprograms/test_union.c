#include <stdio.h>

union IP4 {
	unsigned char c[4];
	unsigned int i;
};

void test_ip() {
	union IP4 ip4;
	ip4.c[0] = 127;
	ip4.c[1] = 0;
	ip4.c[2] = 0;
	ip4.c[3] = 1;
	printf("%u.%u.%u.%u\n", ip4.c[0], ip4.c[1], ip4.c[2], ip4.c[3]);
	printf("%x\n", ip4.i);
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
            printf("(STR, \"%s\")\n", token->data.str);
            break;
        }
        case NUM: {
            printf("(NUM, %d)\n", token->data.num);
            break;
        }
        case CHAR: {
            printf("(CHAR, '%c')\n", token->data.chr);
        }
    }
}
int main() {
	test_ip();
    struct Token t0 = charToken('c');
    printToken(&t0);
    struct Token t1 = intToken(5);
	printToken(&t1);
    struct Token t2 = strToken("Hello!");
    printToken(&t2);
	//printf("(STR, '%s')", ptr->data.str);
}