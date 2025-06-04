#include <stdlib.h>
#include <string.h>
#include <stdio.h>
int main() {
    char s[] = "Hello";
    printf(strdup(s));
    printf(strdup(s));
}