#include <string.h>
#include <stdio.h>

int g;

void fizzbuzz(int m) {
    int n;
    char buffer[sizeof "fizzbuzz"];
    for (n = 1; n <= m; n++) {
        buffer[0] = '\0';
        if (n % 3 == 0) {
            strcat(buffer, "fizz");
        }
        if (n % 5 == 0) {
            strcat(buffer, "buzz");
        }
        if (buffer[0] != '\0') {
            puts(buffer);
        } else {
            printf("%d\n", n);
        }
    }
}

int main() {
    fizzbuzz(15);
}