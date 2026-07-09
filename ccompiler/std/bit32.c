#include <stdio.h>
#include "bit32.h"
char buffer_base[BUFSIZ];
struct buffer {
    char* data;
    unsigned char read;
    unsigned char write;
    unsigned char size;
    unsigned char ready;
};
struct buffer in_buffer = {buffer_base, 0, 0, 0, 0};
void interrupt() {
    unsigned char i;
    char c;
    for (i = 0; i < 8 && in_buffer.size < BUFSIZ - 1 && (c = in()) != '\0'; i++) {
        out(c);
        if (c == '\b') {
            if (in_buffer.size > 0 && in_buffer.read != in_buffer.write && in_buffer.data[in_buffer.write] != '\n') {
                in_buffer.write--;
                in_buffer.size--;
            }
        } else {
            if (c == '\n')
                in_buffer.ready++;
            in_buffer.data[in_buffer.write++] = c;
            in_buffer.size++;
        }
    }
}
size_t read_keyboard(char* s, size_t n) {
    char c;
    size_t i;
    while (in_buffer.ready == 0)
        ;
    for (i = 0; i < n && in_buffer.size > 0;) {
        in_buffer.size--;
        c = in_buffer.data[in_buffer.read++];
        s[i++] = c;
        if (c == '\n') {
            in_buffer.ready--;
            break;
        }
    }
    return i;
}
void write_teletype(const char* s, size_t n) {
    size_t i;
    for (i = 0; i < n; i++)
        out(*s++);
}