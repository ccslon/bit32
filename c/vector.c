#ifndef STDLIB_H
#include <stdlib.h>
#endif
#ifndef STRING_H
#include <string.h>
#endif

typedef struct {
    unsigned size;
    unsigned capacity;
    void** data;
} Vector;

void initVector(Vector* vector) {
    vector->size = 0;
    vector->capacity = 8;
    vector->data = malloc(sizeof(void*) * vector->capacity);
}

void freeVactor(Vector* vector) {
    free(vector->data);
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
        void** temp = malloc(sizeof(void*) * vector->capacity);
        memcpy(temp, vector->data, vector->size);
        free(vector->data);
        vector->data = temp;
    }
    vector->data[vector->size++] = value;
    return vector->size;
}

void* pop(Vector* vector) {
    if (vector->size == 0) {
        return NULL;
    }
    void* ret = vector->data[vector->size--];
    if (vector->size < vector->capacity / 2) {
        vector->capacity /= 2;
        void** temp = malloc(sizeof(void*) * vector->capacity);
        memcpy(temp, vector->data, vector->size);
        free(vector->data);
        vector->data = temp;
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
    unsigned buf_index;
    unsigned i;
    unsigned n = strlen(str)
    for (i = 0; i < n; i++) {
        buf_index = 0;
        buffer[0] = '\0';
        char c = str[i];
        if (c == ' ' || c == '\t' || c == '\n') {
            char* 
        }
    }

    return vector
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