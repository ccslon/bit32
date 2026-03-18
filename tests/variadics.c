#include <stdarg.h>
void uprint(unsigned);
void dprint(int);
void xprint(unsigned, char);
void fprint(float, int);
void eprint(float, int);
void oprint(unsigned);
void putchar(char);

void printf(const char* format, ...) {
    va_list ap;
    va_start(ap, format);
    const char* c;
    unsigned n = 0;
    for (c = format; *c; c++, n++) {
        if (*c == '%') {
            c++;
            char precision = 0; 
            if ('0' <= *c && *c <= '9') {
                precision = *c++ - '0';
            }
            switch (*c) {
                case 'u':
                    uprint(va_arg(ap, unsigned));
                    break;
                case 'd':
                case 'i':
                    dprint(va_arg(ap, int));
                    break;
                case 'x':
                    xprint(va_arg(ap, unsigned), 'a');
                    break;
                case 'X':
                    xprint(va_arg(ap, unsigned), 'A');
                    break;
                case 'f':
                    fprint(va_arg(ap, float), precision);
                    break;
                case 'e':
                    eprint(va_arg(ap, float), precision);
                    break;
                case 's':
                    printf(va_arg(ap, char*));
                    break;
                case 'c':
                    putchar(va_arg(ap, char));
                    break;
                case 'o':
                    oprint(va_arg(ap, unsigned));
                    break;
                case 'n':
                    *va_arg(ap, unsigned*) = n;
                    break;
                default:
                    putchar(*c);
            }
        } else {
            putchar(*c);
        }
    }
    va_end(ap);
}

int main() {
    printf("%d%d%d%d%d", 1,2,3,4,5);
}