#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define LEN 5

int intcmp(int* a, int* b) {
    return *a - *b;
}
#define STRS_LEN 4
int arr[LEN] = {4, 6, 2,3,1};

void main() {
    int i;
    for (i = 0; i < LEN; i++)
        arr[i] = rand() % 10000;
    for (i = 0; i < LEN; i++)
        printf("%d ", arr[i]);
    putchar('\n');
    qsort(arr, sizeof(int), 0, LEN-1, intcmp);
    for (i = 0; i < LEN; i++)
        printf("%d ", arr[i]);
    
}