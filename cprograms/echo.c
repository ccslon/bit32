#include <stdio.h>
#define BUF_SIZE 16
int main() {
    char buf[BUF_SIZE];
    gets(buf, BUF_SIZE);
    puts(buf);
    return 0;
}