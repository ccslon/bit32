#include <stdio.h>

int dofib(const int n, const int a, const int b) {
    switch (n) {
        case 1: return a;
        case 2: return b;
        default: {
            return dofib(n-1, b, a+b);
        }
    }
}
int fib(const int n) {
    return dofib(n, 0, 1);
}

unsigned int ifact(unsigned int n, unsigned int f) {
    if (n == 0)
        return f;
    return ifact(n-1, n*f);
}

unsigned int fact(unsigned int n) {
    return ifact(n, 1);
}