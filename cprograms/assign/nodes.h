#ifndef NODES_H
#define NODES_H
#include "lexer.h"

enum NodeType {
    NUMBER,
    VARIABLE,
    BINARY,
    ASSIGN
};

struct Node;

typedef struct Binary {
    int (*op)(int, int);
    struct Node* left;
    struct Node* right;
} Binary;

typedef struct Node {
    enum NodeType type;
    Token* token;
    union {
        int num;
        char* name;
        Binary* binary;
    };
} Node;

Node* allocNumber(Token*);

Node* allocVariable(Token*);

#define OP(name, op) int name(int l, int r) { return l op r; }

Node* allocBinary(Token*, Node*, Node*);

Node* allocAssign(Token*, Node*, Node*);

void freeNode(Node*);

int eval(Node*);

void printNode(Node*);
#endif
