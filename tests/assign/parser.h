#ifndef PARSER_H
#define PARSER_H
#include <stdbool.h>
#include "nodes.h"

Token* next();

bool peekToken(enum TokenType);

bool peek(char);

bool accept(char);

void expectToken(enum TokenType);

void expect(char);

Node* factor();

Node* term();

Node* expr();

Node* assign();

Node* parse(Token*);
#endif
