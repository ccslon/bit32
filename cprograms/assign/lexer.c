#include <ctype.h>
#include <errno.h>
#include <setjmp.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lexer.h"

char* TokenTypeMap[5] = {
    "NUM",
    "VAR",
    "SYM",
    "BAD",
    "END"
};

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

unsigned consume(Token* new, char* input, enum TokenType type, int (*test)(int)) {
    unsigned i = 0;    
    char lexeme[LEXEME_SIZE];
    char len = 0;
    do {
        lexeme[len++] = input[i++];
    } while (len < LEXEME_SIZE-1 && (*test)(input[i]));
    lexeme[len] = '\0';
    new->lexeme = strdup(lexeme);
    new->type = type;    
    return i;
}

extern jmp_buf jmp;

Token* lex(char* input) {
    unsigned i = 0;
    unsigned len = strlen(input);    
    Token* head = NULL;
    Token* tail = NULL;
    while (i < len) {
        if (isspace(input[i])) {
            // if (input[i] == '\n');
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
