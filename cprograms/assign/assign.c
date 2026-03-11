#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <errno.h>
#include <setjmp.h>

#include "intmap.h"

#define EINV_SYM 200
#define ENAME 201
#define EEXPECTED 202
#define EASSIGN 203

jmp_buf jmp;

// Lexer
enum TokenType {
    NUM,
    VAR,
    SYM,
    BAD,
    END
};

char* TokenTypeMap[5] = {
    "NUM",
    "VAR",
    "SYM",
    "BAD",
    "END"
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
    Token* temp;
    while (head != NULL) {
        switch (head->type) {
            case NUM:
            case VAR:
                free(head->lexeme);
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
    do {
        lexeme_buffer[lexeme_len++] = input[i++];
    } while ((*test)(input[i]) && lexeme_len < LEXEME_BUFFER_SIZE-1);
    lexeme_buffer[lexeme_len] = '\0';
    new->lexeme = strdup(lexeme_buffer);
    new->type = type;    
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
            } else if (isalpha(input[i])) {
                i += consume(new, &input[i], VAR, isalpha);
            } else {
                switch (input[i]) {
                    case '(':
                    case ')':
                    case '+':
                    case '-':
                    case '*':
                    case '/':
                    case '=':
                        new->type = SYM;
                        new->sym = input[i++];
                        break;
                    default:
                        printf("Bad token \"%c\"\n", input[i]);
                        free(new);
                        new = NULL;
                        errno = EINV_SYM;
                        longjmp(jmp, 1);
                }
            }
            new->line = line;
            if (head == NULL) {
                head = tail = new;
            } else {
                tail->next = new;
                tail = new;
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
                printf("(VAR \"%s\")\n", head->lexeme);
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

#define OP(name, op) int name(int l, int r) { return l op r; }
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

IntMap* env;

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

// Parser
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

Node* expr();

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
    IntMap_set(env, "foo", 10);
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

