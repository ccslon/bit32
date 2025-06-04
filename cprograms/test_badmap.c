// int strcmp(const char*, const char*);
// void printf(char, ...);
// #define NULL (void*)0
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


typedef struct {
    char* key;
    int value;
} Pair;

#define ENV_MAX_SIZE 4

Pair env[ENV_MAX_SIZE] = {
    {"a", 3},
    {"b", 4},
    {"c", 7},
    {"foo", 10}
};

// bool contains(Table* table, char* key);
// int set(Table* table, char* key, int value);
Pair* get(char* key) {
    unsigned i;
    for (i = 0; i < ENV_MAX_SIZE; i++) {
        if (strcmp(key, env[i].key) == 0) {
            return &env[i];
        }
    }
    return NULL;
}

int main() {
    Pair* a = get("a");
    Pair* b = get("b");
    printf("%d\n", a->value + b->value);
    return 0;
}