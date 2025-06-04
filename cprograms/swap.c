//typedef unsigned size_t;
#include <stdio.h>
void my_swap(void* v, size_t size, int i, int j) { //0x8b7, 0x1ab, 0x1b5
    const size_t words = size / sizeof(int);
    const char tail = size % sizeof(int);    
    int t, *vi, *vj;
    size_t k;
    if (words > 0) {        
        vi = v + i*size;
        vj = v + j*size;
        for (k = 0; k < words; k++) {
            t = vi[k];
            vi[k] = vj[k];
            vj[k] = t;
        }
    }
    if (tail > 0) {
        char c;
        char* vik = vi + k;
        char* vjk = vj + k;
        for (c = 0; c < tail; c++) {
            t = vik[c];
            vik[c] = vjk[c];
            vjk[c] = t;
        }
    }    
}

void bad_swap(void* v, size_t size, int i, int j) { //0x39c
    char temp, *ci = v + i*size, *cj = v + j*size;
    size_t k;
    for (k = 0; k < size; k++) {
        temp = ci[k];
        ci[k] = cj[k];
        cj[k] = temp;
    }
}

typedef struct {
    char c;
    int i;
} Foo;
typedef struct {
    char a, b, c;
    int i, j, k, l, m, n;
} Bar;
#define LEN 2

#include <stdlib.h>
#include <string.h> //0x8c0, 0x177, 0x181

#define SWAP my_swap

void foo() {
    Foo a[LEN] = {{'a', 1}, {'x', 12}};
    size_t i;
    for (i = 0; i < LEN; i++) {
        printf("%c %d\n", a[i].c, a[i].i);
    }
    SWAP(a, sizeof(Foo), 0, 1);
    for (i = 0; i < LEN; i++) {
        printf("%c %d\n", a[i].c, a[i].i);
    }
}

void bar() {
    Bar a[LEN] = {{'a','b','c', 1,2,3,4,5,6}, {'x','y','z', 7,8,9,10,11,12}};
    size_t i;
    SWAP(a, sizeof(Bar), 0, 1);
    for (i = 0; i < LEN; i++) {
        printf("%c%c%c %d\n", a[i].a, a[i].b, a[i].c, a[i].n);
    }
}

int main() {
    bar();
    return 0;
}