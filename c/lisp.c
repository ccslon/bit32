
typedef struct _node_ {
    void* value
    struct _node_* next;
} Node;

Node cons(void* value, Node* next) {
    Node new = {value, next};
    return new;
}

/*
S_EXPR -> ATOM | LIST
ATOM -> const|id
LIST -> '(' [S_EXPR {' ' S_EXPR}] ')'
*/