#include <stdio.h>
unsigned int fact(unsigned int n) {
    if (n == 0)
        return 1;
    return n * fact(n-1);
}
unsigned int fact(unsigned int n) {
    unsigned int f = 1;
    while (n)
        f *= n--;
    return f;
}
int main() {
    printf("%d\n", fact(6));
    return 0;
}