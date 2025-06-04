#include <stdarg.h>
void simple_print(const char *str, ...) {
    va_list args;
    va_start(args, str);

    int num = va_arg(args, int);
                
    char *s = va_arg(args, char *);

    va_end(args);
}