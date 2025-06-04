#include <stdio.h>
void swap(void*,unsigned,int,int);
void foo() {
    int bar[2] = {1234, 5678};
    //("%d %d\n", bar[0], bar[1]);
    swap(bar, sizeof(int), 0, 1);
    //printf("%d %d\n", bar[0], bar[1]);
}

void swap(void* v, unsigned size, int i, int j) {
    //size_t words = size / sizeof(int);
    //size_t tail = size % sizeof(int);    
    int t;
    //unsigned k;

    t = *(int*)(v+i);
    //printf("%d\n", t);
    *(int*)(v+i*size) = *(int*)(v+j);
    //printf("%d\n", *(int*)(v+i));
    *(int*)(v+j) = t;
}

int main() {
    foo();
}