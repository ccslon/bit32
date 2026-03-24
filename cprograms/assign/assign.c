#include <setjmp.h>
#include <stdio.h>
#include <string.h>

#include "intmap.h"
// #include "lexer.h"
// #include "nodes.h"
#include "parser.h"

jmp_buf jmp;
IntMap* env;
IntMap* n = NULL;
void exec(char* input) {
    Token* head = NULL;
    Node* tree = NULL;
    if (setjmp(jmp) == 0) {
        head = lex(input);
        printTokens(head);
        tree = parse(head);
        printNode(tree);
        putchar('\n');
        int value = eval(tree);
        printf("%d\n", value);
    }
    freeNode(tree);
    tree = NULL;
    freeTokens(head);
    head = NULL;
}

void loop();

int main() {

    env = allocIntMap();
    IntMap_set(env, "a", 3);
    IntMap_set(env, "b", 4);
    IntMap_set(env, "c", 7);
    // IntMap_set(env, "foo", 10);
    puts("Testing123");
    exec("a+b*c");
    exec("(a+b)*c");
    exec("x = a + 1");
    exec("x");
    puts("Welcome");
    loop();
    freeIntMap(env);
    return 0;
}

#define BUF_SIZE 32
void loop() {
	char buf[BUF_SIZE];
	while(1) {
        buf[0] = '\0';
		fgets(buf, BUF_SIZE, stdin);
		if (strcmp(buf, "quit") == 0) {
			return;
		}
        exec(buf);
    }
}
