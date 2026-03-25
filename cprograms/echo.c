#include <stdio.h>
#define BUF_SIZE 32
int main() {
    char buf[BUF_SIZE];
    while (1) {
        buf[0] = '\0';
        fgets(buf, BUF_SIZE, stdin);
        printf("%s\n", buf);
    }
    return 0;
}