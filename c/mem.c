#include <stdio.h>
#include <string.h>
char msg[4] = "Hi!";

int main() {
    char buf[10] = "Hello";
    printf(msg);
    printf(buf);
    memcpy(buf, msg, sizeof msg);
    printf(buf);
}