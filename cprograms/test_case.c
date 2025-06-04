#define NULL (void*)0
void free(void*);

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
            case VAR:
                free(head->lexeme);
        }
        temp = head;
        head = head->next;
        free(temp);
    }
}