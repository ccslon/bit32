#include <stdlib.h>
#include <string.h>
#include <stdio.h>
typedef struct {
    unsigned size;
    unsigned capacity;
    void** data;
} Vector;

void initVector(Vector* vector) {
    vector->size = 0;
    vector->capacity = 8;
    vector->data = malloc(vector->capacity * sizeof(void*));
}

void freeVector(Vector* vector) {
    unsigned i;
    for (i = 0; i < vector->size; i++) {
        free(vector->data[i]);
    }
    free(vector->data);
    free(vector);
}

void* get(Vector* vector, unsigned index) {
    if (index >= vector->capacity) {
        return NULL;
    }
    return vector->data[index];
}

void set(Vector* vector, unsigned index, void* value) {
    if (index < vector->capacity) {
        vector->data[index] = value;
    }
}

unsigned push(Vector* vector, void* value) {
    if (vector->size == vector->capacity) {
        vector->capacity *= 2;
        vector->data = realloc(vector->data, vector->capacity * sizeof(void*));
    }
    vector->data[vector->size++] = value;
    return vector->size;
}

void* pop(Vector* vector) {
    if (vector->size == 0) {
        return NULL;
    }
    void* ret = vector->data[vector->size--];
    if (vector->size > 8) {
        vector->capacity /= 2;
        vector->data = realloc(vector->data, vector->capacity * sizeof(void*));
    }
    return ret;
}

void iter(Vector* vector, void (*f)(void*)) {
    unsigned i;
    for (i = 0; i < vector->size; i++) {
        (*f)(vector->data[i]);
    }
}

#define BUF_SIZE 32
Vector* split(char* str) {
    Vector* vector = malloc(sizeof(Vector));
    initVector(vector);
    char buffer[BUF_SIZE];
    unsigned i, b = 0, n = strlen(str);
    for (i = 0; i < n; i++) {
        switch (str[i]) {
            case ' ':
            case '\t':
                buffer[b] = '\0';
                push(vector, strdup(buffer));
                buffer[(b = 0)] = '\0';
                break;
            default:
                buffer[b++] = str[i];
        }
    }
    if (b > 0) {
        buffer[b] = '\0';
        push(vector, strdup(buffer));
    }
    return vector;
}

void print(void* s) {
    printf("%s\n", s);
}

int main() {
    Vector* v = split("Hello my name is Colin Hello my name is Colin");
    // Vector* v = split("Hello my name is Colin");
    // Vector* v = split("a b");
    iter(v, print);
    freeVector(v);
    return 0;
}

/*
Vector* -> Vector {
           u32 size
           u32 capacity
           ptr data     ->  ptr, -> char*
           }                ptr, -> char*
                            ptr, -> char*
                            ...
*/