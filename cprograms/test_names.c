enum TokenType {
    NUM,
    VAR,
    SYM,
    INVALID,
    END
};

typedef struct token {
    enum TokenType type;
    union {
        char* lexeme;
        char sym;
    };
    short line;
    struct token* next;
} Token;



Token makeToken() {
    Token token;
    token.type = SYM;
    token.lexeme = "123";
    token.sym = '+';
    token.line = 1;
    token.next = (void*)0;
    return token;
}