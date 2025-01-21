#include <string.h>
#include <stdlib.h>
#include <stdio.h>
// char* strcat(char*, const char*);
// int strlen(const char*);
// void printf(const char*, ...);

void fizzbuzz(int m) {
    int n;
    char buffer[9]; // "fizzbuzz\0"
    for (n = 1; n <= m; n++) {
        buffer[0] = '\0';
        if (n % 3 == 0) {
            strcat(buffer, "fizz");
        }
        if (n % 5 == 0) {
            strcat(buffer, "buzz");
        }
        if (strlen(buffer)) {
            printf("%s\n", buffer);
        } else {
            printf("%d\n", n);
        }
    }
}

int main() {
    fizzbuzz(15);
}