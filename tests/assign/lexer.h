#ifndef LEXER_H
#define LEXER_H

#define EINV_SYM 200

enum TokenType {
    NUM,
    VAR,
    SYM,
    BAD,
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

void freeTokens(Token*);

#define LEXEME_BUFFER_SIZE 16

unsigned consume(Token*, char*, enum TokenType, int (*)(int));

Token* lex(char*);

void printTokens(Token*);
#endif
