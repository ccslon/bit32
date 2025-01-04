void crash();
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>

// "HashMap"
typedef struct {
    char* key;
    int value;
} Entry;

#define ENV_MAX_SIZE 4

Entry env[ENV_MAX_SIZE] = {
    {"a", 3},
    {"b", 4},
    {"c", 7},
    {"foo", 10}
};

// bool contains(Table* table, char* key);
// int set(Table* table, char* key, int value);
Entry* get(char* key) {
    unsigned i;
    for (i = 0; i < ENV_MAX_SIZE; i++) {
        if (strcmp(key, env[i].key) == 0) {
            return &env[i];
        }
    }
    return NULL;
}

// Lexer
enum TokenType {
    NUM,
    VAR,
    SYM,
    INVALID,
    END
};

typedef struct Token {
    enum TokenType type;
    union {
        char* lexeme;
        char sym;
    };
    short line;
    struct Token* next;
} Token;

void freeTokens(Token* head) {
    Token* temp = head;
    while (head != NULL) {
        switch (head->type) {
            case NUM:
            case VAR: {
                free(head->lexeme);
            }
        }
        temp = head;
        head = head->next;
        free(temp);
    }
}

#define LEXEME_BUFFER_SIZE 16

unsigned consume(Token* new, char* input, enum TokenType type, int (*test)(int)) {
    unsigned i = 0;    
    char lexeme_buffer[LEXEME_BUFFER_SIZE];
    char lexeme_len = 0;
    lexeme_buffer[lexeme_len++] = input[i++];
    while ((*test)(input[i]) && lexeme_len < LEXEME_BUFFER_SIZE) {
        lexeme_buffer[lexeme_len++] = input[i++];
    }
    lexeme_buffer[lexeme_len] = '\0';
    char* lexeme = malloc(lexeme_len+1);
    new->type = type;
    strncpy(lexeme, lexeme_buffer, lexeme_len+1);
    new->lexeme = lexeme;
    return i;
}

Token* lex(char* input) {
    unsigned i = 0;
    unsigned len = strlen(input);
    Token* head = NULL;
    Token* tail = NULL;
    short line = 1;
    while (i < len) {
        if (isspace(input[i])) {
            if (input[i] == '\n') {
                line++;
            }
            i++;
        } else {
            Token* new = malloc(sizeof(Token));
            if (isdigit(input[i])) {
                i += consume(new, &input[i], NUM, isdigit);
                new->line = line;
            } else if (isalpha(input[i])) {
                i += consume(new, &input[i], VAR, isalpha);
                new->line = line;
            } else {
                switch (input[i]) {
                    case '(':
                    case ')':
                    case '+':
                    case '-':
                    case '*':
                    case '/':
                        new->type = SYM;
                        new->sym = input[i++];
                        new->line = line;
                        break;
                    default:
                        printf("Invalid token %c\n", input[i]);
                }
            }
            if (head == NULL) {
                head = tail = new;
            } else {
                tail->next = new;
                tail = tail->next;
            }            
        }
    }
    Token* end = malloc(sizeof(Token));
    end->type = END;
    end->sym = '\0';
    end->line = line;
    end->next = NULL;
    tail->next = end;
    return head;
}

void printTokens(Token* head) {
    for (; head != NULL; head = head->next) {
        switch (head->type) {
            case NUM:
                printf("(NUM %s)\n", head->lexeme);
                break;
            case VAR:
                printf("(STR \"%s\")\n", head->lexeme);
                break;
            case SYM:
                printf("(SYM '%c')\n", head->sym);
        }
    }
}

// Nodes
enum NodeType {
    NUMBER,
    VARIABLE,
    BINARY
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
        char* var;
        Binary* binary;        
    };
} Node;

Node* allocNum(Token* token) {
    Node* node = malloc(sizeof(Node));
    node->type = NUMBER;
    node->token = token;
    node->num = atoi(token->lexeme);
    return node;
}

Node* allocVar(Token* token) {
    Node* node = malloc(sizeof(Node));
    node->type = VARIABLE;
    node->token = token;
    node->var = token->lexeme;
    return node;
}

#define OP(name, op) int name(int l, int r) { return l op r; }
OP(add, +)
OP(sub, -)
OP(mul, *)
OP(div_, /)

Node* allocBinary(Token* token, Node* left, Node* right) {
    Node* node = malloc(sizeof(Node));
    node->type = BINARY;
    node->token = token;
    node->binary = malloc(sizeof(Binary));
    switch (node->token->sym) {
        case '+':
            node->binary->op = add;
            break;        
        case '-':
            node->binary->op = sub;
            break;
        case '*':
            node->binary->op = mul;
            break;
        case '/':
            node->binary->op = div_;
    }
    node->binary->left = left;
    node->binary->right = right;
    return node;
}

void freeNode(Node* node) {
    if (node->type == BINARY) {
        freeNode(node->binary->left);
        freeNode(node->binary->right);
        free(node->binary);
    }
    free(node);
}

int eval(Node* node) {
    switch (node->type) {
        case NUMBER:
            return node->num;
        case VARIABLE: {
            Entry* var = get(node->var);
            if (var == NULL) {
                printf("Cannot find name %s\n", node->var);
            }            
            return var->value;
        }
        case BINARY:
            return (*node->binary->op)(eval(node->binary->left), eval(node->binary->right));
        default: return 0;
    }
}

void printNode(Node* node) {
    switch (node->type) {
        case NUMBER:
            printf("Num %d\n", node->num);
            break;
        case VARIABLE:
            printf("Var %s\n", node->var);
            break;
        case BINARY:
            printNode(node->binary->left);
            printNode(node->binary->right);
            printf("Binary %c\n", node->token->sym);
    }
}

// Parser
Token* current;

Token* next() {
    Token* next = current;
    current = current->next;
    return next;
}

bool peek(enum TokenType type) {
    return current->type == type;
}

bool peek_sym(char sym) {
    return current->sym == sym;
}

bool accept(char sym) {
    if (peek_sym(sym)) {
        next();
        return true;
    }
    return false;
}

void expect(char sym) {
    if (peek_sym(sym)) {
        next();
        return;
    }
    printf("Expected %c\n", sym);
}

Node* expr();

Node* factor() {
    Node* factor;
    if (peek(NUM)) {
        factor = allocNum(next());
    } else if (peek(VAR)) {
        factor = allocVar(next());
    } else if (accept('(')) {
        factor = expr();
        expect(')');
    } else {
        printf("Expected NUM, VAR, or (\n");
    }
    return factor;
}

Node* term() {
    Node* term = factor();
    while (peek_sym('*') || peek_sym('/')) {
        Token* token = next();
        term = allocBinary(token, term, factor());
    }
    return term;
}

Node* expr() {
    Node* expr = term();
    while (peek_sym('+') || peek_sym('-')) {
        Token* token = next();
        expr = allocBinary(token, expr, term());
    }
    return expr;
}

Node* parse(Token* head) {
    current = head;
    Node* root = expr();
    if (current->type != END) {
        printf("Expected END\n");
    }
    return root;
}

void exec(char* input) {
    Token* head = lex(input);
    printTokens(head);
    Node* tree = parse(head);
    printNode(tree);
    printf("%d\n", eval(tree));
    freeNode(tree);
    freeTokens(head);
}

int main() {
    exec("3");
    //exec("9 / (3 * 3");
    exec("1+2");
    return 0;
}