#include <stdio.h>

int sqr(int n) {
    return n * n;
}

int sum(int n, int (*f)(int)) {
    int s = 0, i;
    for (i = 1; i <= n; i++) {
        s += (*f)(i);
    }
    return s;
}

int main() {
    printf("%d", sum(5, sqr));
    return 0;
}