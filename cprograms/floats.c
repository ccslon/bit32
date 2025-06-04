#include <stdio.h>
#define PI 3.141592
float pi = 3.141592;
float decimal(float f) {
    return f - (int)f;
}
/*
round:
    push A, B
    ld A, [f]
    ld B, [f]
    fti B, B
    itf B, B
    subf A, B
    fti A, A
    pop A, B
    ret
*/
int main() {
    printf("Hi!\n");
    printf("%d %x\n", 34, 0xab);
    printf("%5f\n", pi);
    printf("%5f\n", 1.0/16.0);
    printf("%e\n", 1000000.0);
    // eprint(1000000.0, 3);
    // eprint(0.0, 3);
    return 0;
}