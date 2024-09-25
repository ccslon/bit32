#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#define BUF_LEN 100

char BUFFER[BUF_LEN];

int main() {
	char c;
    size_t i = 0;
    bool go = true;
    while (go) {
        c = getchar();
        if (c) {
            switch (c) {
                case '\n': {
                    putchar(c);
                    if (strcmp(BUFFER, "quit") == 0) {
                        go = false;
                    } else {
                        if (strcmp(BUFFER, "hello") == 0) {
                            puts("Hello world!");
                        } else {
                            puts(BUFFER);
                        }
                    }
                    BUFFER[i = 0] = '\0';
                    break;
                }
                case '\b': {
                    i = i > 0 ? i - 1 : 0;
                    putchar(c);
                    break;
                }
                default: {
                    BUFFER[i] = c;
                    i = (i+1) % BUF_LEN;
                    BUFFER[i] = '\0';                    
                    putchar(c);
                }
            }
        }
    }
    puts("Halt");
}