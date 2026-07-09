#include <ctype.h>
#include <setjmp.h>
#include <stdio.h>
#include <errno.h>
#include "parser.h"
#include "nodes.h"

#define EEXPECTED 202
#define EASSIGN 203

Token* current;

Token* next() {
    Token* next = current;
    current = current->next;
    return next;
}

bool peekToken(enum TokenType type) {
    return current->type == type;
}

bool peek(char sym) {
    return current->sym == sym;
}

bool accept(char sym) {
    if (peek(sym)) {
        next();
        return true;
    }
    return false;
}

extern char* TokenTypeMap[];
extern jmp_buf jmp;

void expectToken(enum TokenType token) {
    if (peekToken(token)) {
        next();
        return;
    }
    printf("Expected %s\n", TokenTypeMap[token]);
    errno = EEXPECTED;
    longjmp(jmp, 1);
}

void expect(char sym) {
    if (peek(sym)) {
        next();
        return;
    }
    printf("Expected %c\n", sym);
    errno = EEXPECTED;
    longjmp(jmp, 1);
}

Node* factor() {
    Node* factor;
    if (peekToken(NUM)) {
        factor = allocNumber(next());
    } else if (peekToken(VAR)) {
        factor = allocVariable(next());
    } else if (accept('(')) {
        factor = expr();
        expect(')');
    } else {
        printf("Expected NUM, VAR, or (\n");
        errno = EEXPECTED;
        longjmp(jmp, 1);
    }
    return factor;
}

Node* term() {
    Node* term = factor();
    while (peek('*') || peek('/')) {
	    Token* token = next();
        term = allocBinary(token, term, factor());
    }
    return term;
}

Node* expr() {
    Node* expr = term();
    while (peek('+') || peek('-')) {
        Token* token = next();
	    expr = allocBinary(token, expr, term());
    }
    return expr;
}

Node* assign() {
    Node* assign = expr();
    if (peek('=')) {
        if (assign->type != VARIABLE){
            printf("Can only assign to variables");
            errno = EASSIGN;
            freeNode(assign);
            assign =  NULL;
            longjmp(jmp, 1);
        }
        Token* token = next();
        assign = allocAssign(token, assign, expr());
    }
    return assign;
}

Node* parse(Token* head) {
    current = head;
    Node* root = assign();
    expectToken(END);
    return root;
}
