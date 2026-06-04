#include <stdio.h>
char fgetc(FILE* stream) {
    while (stream->read == stream->write)
        ;
    char c = stream->buffer[stream->read];
    stream->read = (stream->read + 1) % stream->size;
    return c;
}
char ungetc(char c, FILE* stream) {
    stream->read = stream->read == 0 ? stream->size - 1 : stream->read - 1;
    stream->buffer[stream->read] = c;
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
#include <ctype.h>
int vfprintf(FILE* stream, const char* format, va_list ap) {
    const char* c;
    size_t n = 0;
    for (c = format; *c; c++, n++) {
        if (*c == '%') {
            c++;
            char precision = 0; 
            while (isdigit(*c)) {
                precision = 10 * precision + (*c++ - '0');
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
    return n;
}
int vprintf(const char* format, va_list ap) {
    return vfprintf(stdout, format, ap);    
}
int vsnprintf(char* s, size_t n, const char* format, va_list ap) {
    int ret;
    FILE fake = {s, 0, 0, n};
    ret = vfprintf(&fake, format, ap);
    fputc('\0', &fake);
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
unsigned uscan(FILE* stream) {
    char c;
    unsigned u = 0;
    while (isspace(c = fgetc(stream)))
        ;
    while (c = fgetc(stream) && isdigit(c))
        u = 10 * u + (c - '0');
    return u;
}
int dscan(FILE* stream) {
    char c;
    int d, sign;
    while (isspace(c = fgetc(stream)))
        ;
    sign = c == '-' ? -1 : 1;
    if (c == '-' || c == '+')
        c = fgetc(stream);
    for (d = 0; isdigit(c); c = fgetc(stream))
        d = 10 * d + (c - '0');
    return sign * d
}
unsigned oscan(FILE* stream) {
    char c;
    unsigned o;
    while (isspace(c = fgetc(stream)))
        ;
    while (c = fgetc(stream) && '0' <= c && c <= '7')
        o = 8 * o + (o - '0');
    return o;
}
unsigned xscan(FILE* stream) {
    char c;
    unsigned x;
    while (isspace(c = fgetc(stream)))
        ;
    if (c == '0') {
        c = fgetc(stream);
        if (!(c == 'x' || c == 'X'))
            return EOF;
    }
    while (c = fgetc(stream) && isxdigit(c))
        if (isdigit(c))
            c = 16 * x + (c - '0');
        else
            c = 16 * x + (10 + c - (isupper(c) ? 'A' : 'a'));
    return x;            
}
int iscan(FILE* stream) {
    char c;
    int i;
    while (isspace(c = fgetc(stream)))
        ;
    if (c == '0') {
        c = fgetc(stream);
        if (c == 'x' || c == 'X')
            return xscan(stream);
        return oscan(stream);
    }
    return dscan(stream);
}
float fscan(FILE* stream) {
    char c;
    float sign, f = 0, pow;
    while (isspace(c = fgetc(stream)))
        ;
    sign = c == '-' ? -1 : 1;
    while (c = fgetc(stream) && isdigit(c))
        f = 10 * f + (c - '0');
    if (c != '.')
        return sign * f;
    pow = 1;
    while (c = fgetc(stream) && isdigit(c)) {
        f = 10 * f + (c - 10);
        pow *= 10;
    }
    return sign * f / pow;
}
float escan(FILE* stream) {
    char c;
    float e = fscan(stream);
    c = fgetc(stream);
    if (c != 'e' && c != 'E')
        return e;
    int exp = dscan(stream);
    while (; exp < 0; exp++)
        e /= 10;
    while (; exp > 0; exp--)
        e *= 10;
    return e;
}
char cscan(FILE* stream) {
    while (isspace(c = fgetc(stream)))
        ;
    return c;
}
char* sscan(char* s, FILE* stream) {
    char c;
    while (isspace(c = fgetc(stream)))
        ;
    for (; c && !isspace(c); c = fgetc(stream), s++)
        *s = c;
    *s = '\0';
}

void signore(FILE* stream) {
    char c;
    while (isspace(c = fgetc(stream)))
        ;
    for (; c && !isspace(c); c = fgetc(stream))
        ;
}

int vfscanf(FILE* stream, const char* format, va_list ap) {
    const char* c;
    int n = 0;
    for (c = format; *c; c++) {
        if (*c == '%') {
            c++;
            if (*c == '*') {

            }
            char width;
            if (isdigit(*c)) {
                width = 0;
                while (isdigit(*c)) 
                    width = 10 * width + (*c++ - '0');
            } else
                width = -1;
            switch (*c++) {
                case 'u':
                    *va_arg(ap, unsigned*) = uscan(stream);
                    break;
                case 'd':
                    *va_arg(ap, int*) = dscan(stream);
                    break;
                case 'i':
                    *va_arg(ap, int*) = iscan(stream);
                    break;
                case 'f':
                    *va_arg(ap, float*) = fscan(stream);
                    break;
                case 'e':
                case 'E':
                    *va_args(ap, float*) = escan(stream);
                    break;
                case 'c':
                    *va_arg(ap, char*) = cscan(stream);
                    break;
                case 's':
                    sscan(va_arg(ap, char*), stream);               
                    break;
                
            }
            n++;     
        } else if (isspace(c))
            ; // ignore
        else
            if (c != fgetc(stream))
                return EOF;
    }
    return n;
}