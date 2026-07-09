#include <stdio.h>
#include <string.h>
#define BUF_SIZE 32
int main() {
    char buf[BUF_SIZE];
    while (1) {
        buf[0] = '\0';
        fgets(buf, BUF_SIZE, stdin);
        if (strncmp(buf, "quit", BUF_SIZE) == 0)
            break;
        fputs(buf, BUF_SIZE, stdout);
    }
    return 0;
}