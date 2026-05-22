#include <errno.h>
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include "intmap.h"
#include "nodes.h"

#define ENAME 201

Node* allocNumber(Token* token) {
    Node* node = malloc(sizeof(Node));
    node->type = NUMBER;
    node->token = token;
    node->num = atoi(token->lexeme);
    return node;
}

Node* allocVariable(Token* token) {
    Node* node = malloc(sizeof(Node));
    node->type = VARIABLE;
    node->token = token;
    node->name = token->lexeme;
    return node;
}

OP(add_, +)
OP(sub_, -)
OP(mul_, *)
OP(div_, /)

Node* allocBinary(Token* token, Node* left, Node* right) {
    Node* node = malloc(sizeof(Node));
    node->type = BINARY;
    node->token = token;
    node->binary = malloc(sizeof(Binary));
    switch (node->token->sym) {
        case '+':
            node->binary->op = add_;
            break;        
        case '-':
            node->binary->op = sub_;
            break;
        case '*':
            node->binary->op = mul_;
            break;
        case '/':
            node->binary->op = div_;
    }
    node->binary->left = left;
    node->binary->right = right;
    return node;
}

Node* allocAssign(Token* token, Node* left, Node* right) {
    Node* node = malloc(sizeof(Node));
    node->type = ASSIGN;
    node->token = token;
    node->binary = malloc(sizeof(struct Binary));
    node->binary->op = NULL;
    node->binary->left = left;
    node->binary->right = right;
    return node;
}

void freeNode(Node* node) {
    if (node != NULL) {
        switch (node->type) {
            case BINARY:
            case ASSIGN:
                freeNode(node->binary->left);
                freeNode(node->binary->right);
                free(node->binary);
        }
        free(node);
    }
}

extern IntMap* env;
extern jmp_buf jmp;

int eval(Node* node) {
    switch (node->type) {
        case NUMBER:
            return node->num;
        case VARIABLE: {
            Pair* var = IntMap_get(env, node->name);
            if (var == NULL) {
                printf("Cannot find name %s\n", node->name);
                errno = ENAME;
                longjmp(jmp, 1);
            }
            return var->value;
        }
        case BINARY:
            return (*node->binary->op)(eval(node->binary->left), eval(node->binary->right));
        case ASSIGN: {
            int value = eval(node->binary->right);
            IntMap_set(env, node->binary->left->name, value);
            return value;
        }
    }
}

void printNode(Node* node) {
    switch (node->type) {
        case NUMBER:
            printf("%d ", node->num);
            break;
        case VARIABLE:
            printf("%s ", node->name);
            break;
        case BINARY:
            printNode(node->binary->left);
            printNode(node->binary->right);
            printf("%c ", node->token->sym);
    }
}
