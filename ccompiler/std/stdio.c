#include <stdio.h>
char fgetc(FILE* stream) {
    while (stream->read == stream->write)
        ;
    char c = stream->buffer[stream->read];
    stream->read = (stream->read + 1) % stream->size;
    return c;
}
char getchar() {
    while (stdin->read == stdin->write)
        ;
    char c = stdin->buffer[stdin->read];
    stdin->read = (stdin->read + 1) % stdin->size;
    return c;
}
char* fgets(char* s, size_t n, FILE* stream) {
    size_t i = 0;
    char c;
    if (n > 0) {
        while (i < n-1 && (c = fgetc(stream)) && c != '\n') {
            if (c == '\b' && i > 0) {
                i--;
            } else {
                s[i] = c;
                i++;
            }
        }
    }
    s[i] = '\0';
    return s;    
}
char* gets(char* s, size_t n) {
    return fgets(s, n, stdin);
}
int fputc(char c, FILE* stream) {
    stream->buffer[stream->write] = c;
    stream->write = (stream->write + 1) % stream->size;
    return 0;
}
int putchar(char c) {
    stdout->buffer[stdout->write] = c;
    return 0;
}
int fputs(const char* s, FILE* stream) {
    while (*s != '\0') {
        fputc(*s, stream);
        s++;
    }
    return 0;
}
int puts(const char* s) {
    fputs(s, stdout);
    putchar('\n');
    return 0;
}
void uprint(FILE* stream, unsigned n) {
    if (n / 10)
        uprint(stream, n / 10);
    fputc(n % 10 + '0', stream);
}
void oprint(FILE* stream, unsigned n) {
    if (n / 8)
        oprint(stream, n / 8);
    putchar(n % 8 + '0', stream);
}
void dprint(FILE* stream, int n) {
    if (n < 0) {
        fputc('-', stream);
        n = -n;
    }
    uprint(stream, n);
}
void xprint(FILE* stream, unsigned n, char uplo) {
    if (n / 16)
        xprint(stream, n / 16, uplo);
    if (n % 16 > 9)
        fputc(n % 16 - 10 + uplo, stream);
    else
        fputc(n % 16 + '0', stream);
}
void fprint(FILE* stream, float f, char prec) {
    if (f < 0.0) {
        fputc('-', stream);
        f = -f;
    }
    unsigned left = f;
    uprint(stream, left);
    if (prec > 0) {
        fputc('.', stream);
        float right = f - left;
        do {
            right *= 10.0;
            fputc((int)right + '0', stream);
            right -= (int)right;
        } while (--prec > 0);
    }
}
void eprint(FILE* stream, float f, char prec) {
    if (f < 0) {
        fputc('-', stream);
        f = -f;
    }
    int exp = 0;
    if (f) {
        while (f >= 10.0) {
            exp++;
            f /= 10.0;
        }
        while (f < 1.0) {
            exp--;
            f *= 10.0;
        }
    }    
    fprint(stream, f, prec);
    fputc('e', stream);
    dprint(stream, exp);
}
#include <stdarg.h>
int vfprintf(FILE* stream, const char* format, va_list ap) {
    const char* c;
    size_t n = 0;
    for (c = format; *c; c++, n++) {
        if (*c == '%') {
            c++;
            char precision = 0; 
            if ('0' <= *c && *c <= '9') {
                precision = *c++ - '0';
            }
            switch (*c) {
                case 'u':
                    uprint(stream, va_arg(ap, unsigned));
                    break;
                case 'd':
                case 'i':
                    dprint(stream, va_arg(ap, int));
                    break;
                case 'x':
                    xprint(stream, va_arg(ap, unsigned), 'a');
                    break;
                case 'X':
                    xprint(stream, va_arg(ap, unsigned), 'A');
                    break;
                case 'f':
                    fprint(stream, va_arg(ap, float), precision);
                    break;
                case 'e':
                    eprint(stream, va_arg(ap, float), precision);
                    break;
                case 's':
                    fprintf(stream, va_arg(ap, char*));
                    break;
                case 'c':
                    fputc(va_arg(ap, char), stream);
                    break;
                case 'o':
                    oprint(stream, va_arg(ap, unsigned));
                    break;
                case 'n':
                    *va_arg(ap, unsigned*) = n;
                    break;
                default:
                    fputc(*c, stream);
            }
        } else {
            fputc(*c, stream);
        }
    }
    return 0;
}
int vprintf(const char* format, va_list ap) {
    return vfprintf(stdout, format, ap);    
}
int vsnprintf(char* s, size_t n, const char* format, va_list ap) {
    int ret, strlen(char*);
    FILE fake = {s, 0, 0, n};
    ret = vfprintf(&fake, format, ap);
    s[n-1] = '\0';
    return ret;
}
int fprintf(FILE* stream, const char* format, ...) {
    int ret;
    va_list ap;
    va_start(ap, format);
    ret = vfprintf(stream, format, ap);
    va_end(ap);
    return ret;
}
int printf(const char* format, ...) {
    int ret;
    va_list ap;
    va_start(ap, format);
    ret = vprintf(format, ap);
    va_end(ap);
    return ret;
}
int snprintf(char* s, size_t n, const char* format, ...) {
    int ret;
    va_list ap;
    va_start(ap, format);
    ret = vsnprintf(s, n, format, ap);
    va_end(ap);
    return ret;
}