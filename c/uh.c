#include <stdio.h>

#define MY_ARR_LENGTH 5
#define FUNCS_LENGTH 4

int sumfs(int n, int (**f)(int)) {
    int s = 0, i;
    for (i = 0; i < n; i++) {
        s += (*f[i])(i);
    }
    return s;
}

int sum(unsigned int n, int (*f)(int)) {
    int s = 0;
    unsigned int i;
    for (i = 0; i < n; i++)
        s += (*f)(i);
    return s;
}

int sum_array(unsigned char size, int arr[]) {
    int s = 0;
    unsigned char i;
    for (i = 0; i < size; i++) {
        s += arr[i];
    }
    return s;
}

unsigned int fact(unsigned int n) {
    if (n == 0)
        return 1;
    return n * fact(n-1);
}

int main() {
    int (*funcs[FUNCS_LENGTH])(int) = {&fact, &fact, &fact, &fact};
    printf("%d\n", sumfs(FUNCS_LENGTH, funcs));
    int my_arr[MY_ARR_LENGTH] = {1,2,3,4,5};
    printf("%d\n", sum_array(MY_ARR_LENGTH, my_arr));
}