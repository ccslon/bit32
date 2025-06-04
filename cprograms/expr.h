enum TokenType {
    NUM,
    VAR,
    SYM,
    INVALID,
    END
};

typedef struct _token_ {
    enum TokenType type;
    char* lexeme;
    short line;
    struct _token_* next;
} Token;

Token* curr;

char* next() {
    char* value = curr->lexeme;
    curr = curr->next;
    return value;
}

bool peek(enum TokenType type) {
    return curr->type == type;
}

bool peek_sym(char sym) {
    return curr->lexeme[0] == sym;
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
    }
    error();
}

void error() {

}

void factor() {
    if (peek(NUM)) {
        next();
    } else if (peek(VAR)) {
        next();
    } else if (accept('(')) {
        expr();
        expect(')');
    } else {
        error();
    }
}

void term() {
    factor();
    while (peek('*') || peek('/')) {
        next();
        factor();
    }
}

void expr() {
    term();
    while (peek('+') || peek('-')) {
        next();
        term();
    }
}

void parse(Token* token) {
    curr = t;
    expr();
    expect(END);
}