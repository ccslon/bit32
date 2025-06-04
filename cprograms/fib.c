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

int main() {
    printf("%d", fib(8));
    // int i;
    // printf("Fib! %d %d\n", 0, 1);
    // for (i = 1; i <= 10; i++)
    //     printf("%d\n", fib(i));  
}