#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <stdbool.h>
#include "bit32.h"
enum flags {
    _OK =       0b00000,
    _ERROR =    0b00001,
    _READ =     0b00010,
    _WRITE =    0b00100,
    _LINED =    0b01000,
    _EOF =      0b10000
};
char _stdin_base[BUFSIZ];
char _stdout_base[BUFSIZ];
char _stderr_base[1];
FILE _stdin = {_stdin_base, 0, 0, BUFSIZ, _READ, read_keyboard, NULL};
FILE _stdout = {_stdout_base, 0, 0, BUFSIZ, _WRITE | _LINED, NULL, write_teletype};
FILE _stderr = {_stderr_base, 0, 0, 1 /* unbuffered */, _WRITE, NULL, write_teletype};
char fill(FILE* stream) {
    if (stream->flags & (_READ|_ERROR|_EOF) != _READ)
        return EOF;
    if (stream->base == NULL)
        if ((stream->base = malloc(stream->capacity)) == NULL)
            return EOF;
    stream->index = 0;
    stream->size = (*stream->read)(stream->base, stream->capacity);
    if (stream->size == 0) {
        stream->flags |= _EOF;
        return EOF;
    }
    stream->size--;
    return stream->base[stream->index++];
}
char fgetc(FILE* stream) {
    if (stream->size == 0) 
        return fill(stream);
    stream->size--;
    return stream->base[stream->index++];
}
char ungetc(char c, FILE* stream) {
    if (c != EOF) {
        stream->base[--stream->index] = c;
        stream->size++;
    }
    return c;
}
char getchar() {
    return fgetc(stdin);
}
char* fgets(char* s, size_t n, FILE* stream) {
    size_t i = 0;
    char c;
    if (n > 0) {
        while (i < n-1 && (c = fgetc(stream)) != EOF) {
            s[i++] = c;
            if (c == '\n')
                break;
        }
    }
    s[i] = '\0';
    return s;
}
char* gets(char* s, size_t n) {
    size_t i = 0;
    char c;
    if (n > 0) {
        while (i < n-1 && (c = getchar()) != EOF) {
            if (c == '\n')
                break;
            s[i++] = c;
        }
    }
    s[i] = '\0';
    return s;
}
int flush(char c, FILE* stream) {
    if ((stream->flags & (_WRITE|_ERROR)) != _WRITE)
        return EOF;
    if (stream->base == NULL) {
        if ((stream->base = malloc(stream->capacity)) == NULL) {
            stream->flags |= _ERROR;
            return EOF;
        }            
    } else {
        if (((*stream->write)(stream->base, stream->index)) != stream->index) {
            stream->flags |= _ERROR;
            return EOF;
        }
    }
    stream->index = 0;
    stream->size = stream->capacity;
    return c;
}
int fflush(FILE* stream) {
    if (stream->flags & _WRITE)
        return flush(_OK, stream);
    stream->index = 0;
    stream->size = stream->capacity;
    return _OK;
}
#define UNBUFFERED(s) (s->capacity == 1)
int fputc(char c, FILE* stream) {
    if (stream->size == 0)
        if (flush(c, stream) == EOF)
            return EOF;
    stream->size--;
    stream->base[stream->index++] = c;
    if ((stream->flags & _LINED && c == '\n') || UNBUFFERED(stream))
        return flush(c, stream);
    return c;
}
int putchar(char c) {
    return fputc(c, stdout);
}
int fputs(const char* s, size_t n, FILE* stream) {
    size_t i;
    for (i = 0; i < n && *s != '\0'; i++, s++)
        if (fputc(*s, stream) == EOF) {
            stream->flags |= _ERROR;
            return EOF;
        }
    return _OK;
}
int puts(const char* s) {
    fputs(s, BUFSIZ, stdout);
    putchar('\n');
    return _OK;
}
void uprint(FILE* stream, unsigned n) {
    if (n / 10)
        uprint(stream, n / 10);
    fputc(n % 10 + '0', stream);
}
void oprint(FILE* stream, unsigned n) {
    if (n / 8)
        oprint(stream, n / 8);
    fputc(n % 8 + '0', stream);
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
size_t fake_write(const char* s, size_t n) {
    return 0;
}
int vsnprintf(char* s, size_t n, const char* format, va_list ap) {
    int ret;
    FILE fake = {s, 0, 0, n, _WRITE, NULL, fake_write};
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
unsigned uscan(unsigned* ptr, size_t width, FILE* stream) {
    char c;
    size_t i;
    unsigned u;
    while (isspace(c = fgetc(stream)))
        ;
    if (!isdigit(c))
        return _ERROR;
    for (u = 0, i = 0; i < width && isdigit(c); c = fgetc(stream), i++)
        u = 10 * u + (c - '0');
    ungetc(c, stream);
    if (ptr != NULL)
        *ptr = u;
    return _OK;
}
int dscan(int* ptr, size_t width, FILE* stream) {
    char c;
    size_t i;
    int d, sign;
    while (isspace(c = fgetc(stream)))
        ;
    sign = c == '-' ? -1 : 1;
    if (c == '-' || c == '+')
        c = fgetc(stream);
    if (!isdigit(c))
        return _ERROR;
    for (d = 0, i = 0; i < width && isdigit(c); c = fgetc(stream), i++)
        d = 10 * d + (c - '0');
    ungetc(c, stream);
    if (ptr != NULL)
        *ptr = sign * d;
    return _OK;
}
#define isodigit(c) ('0' <= (c) && (c) <= '7')
int oscan(unsigned* ptr, size_t width, FILE* stream) {
    char c;
    size_t i;
    unsigned o;
    while (isspace(c = fgetc(stream)))
        ;
    if (!isodigit(c))
        return _ERROR;
    for (o = 0, i = 0; i < width && isodigit(c); c = fgetc(stream), i++)
        o = 8 * o + (o - '0');
    ungetc(c, stream);
    if (ptr != NULL)
        *ptr = o;
    return _OK;
}
int xscan(unsigned* ptr, size_t width, FILE* stream) {
    char c;
    size_t i;
    unsigned x;
    while (isspace(c = fgetc(stream)))
        ;
    if (c == '0') {
        c = fgetc(stream);
        if (c != 'x' && c != 'X')
            return _ERROR;
    }
    if (!isxdigit(c))
        return _ERROR;
    for (x = 0, i = 0; i < width && (c = fgetc(stream)) && isxdigit(c); i++)
        if (isdigit(c))
            c = 16 * x + (c - '0');
        else
            c = 16 * x + (10 + c - (isupper(c) ? 'A' : 'a'));
    ungetc(c, stream);    
    if (ptr != NULL)
        *ptr = x;
    return _OK;
}
int iscan(int* ptr, size_t width, FILE* stream) {
    char c;
    while (isspace(c = fgetc(stream)))
        ;
    if (c == '0') {
        c = fgetc(stream);
        if (c == 'x' || c == 'X')
            return xscan(ptr, width, stream);
        return oscan(ptr, width, stream);
    }
    return dscan(ptr, width, stream);
}
int fscan(float* ptr, size_t width, FILE* stream) {
    char c;
    size_t i;
    float sign, f, pow;
    while (isspace(c = fgetc(stream)))
        ;
    sign = c == '-' ? -1 : 1;
    if (!isdigit(c))
        return _ERROR;
    for (f = 0, i = 0; i < width && isdigit(c); c = fgetc(stream), i++)
        f = 10 * f + (c - '0');
    if (c != '.') {
        if (ptr != NULL)
            *ptr = sign * f;
        return _OK;
    }        
    c = fgetc(stream);
    if (!isdigit(c))
        return _ERROR;
    pow = 1;
    for (; i < width && isdigit(c); c = fgetc(stream), i++) {
        f = 10 * f + (c - 10);
        pow *= 10;
    }
    ungetc(c, stream);
    if (ptr != NULL)
        *ptr = sign * f / pow;
    return _OK;
}
int escan(float* ptr, size_t width, FILE* stream) {
    char c;
    float e;
    if (fscan(&e, width, stream))
        return _ERROR;
    c = fgetc(stream);
    if (c != 'e' && c != 'E') {
        if (ptr != NULL)
            *ptr = e;
        return _OK;
    }
    int exp;
    if (dscan(&exp, width, stream))
        return _ERROR;
    for (; exp < 0; exp++)
        e /= 10;
    for (; exp > 0; exp--)
        e *= 10;
    if (ptr != NULL)
        *ptr = e;
    return _OK;
}
int sscan(char* ptr, size_t width, FILE* stream) {
    char c;
    size_t i;
    while (isspace(c = fgetc(stream)))
        ;
    if (ptr == NULL)
        for (i = 0; i < width && c && !isspace(c); c = fgetc(stream), i++)
            ;
    else {
        for (i = 0; i < width && c && !isspace(c); c = fgetc(stream), i++)
            ptr[i] = c;
        ptr[i] = '\0';
    }
    ungetc(c, stream);
    return _OK;
}
#define MAYBE_STORE(scanner, type) do { \
    if (scanner(ignore ? NULL : va_arg(ap, type*), width, stream)) \
        return n; \
    if (!ignore) \
        n++; \
} while (0)
int vfscanf(FILE* stream, const char* format, va_list ap) {
    const char* c;
    int n = 0;
    for (c = format; *c; c++) {
        if (*c == '%') {
            bool ignore = false;
            if (*++c == '\0')
                return n;            
            if (*c == '*') {
                ignore = true;
                c++;
            }
            size_t width;
            if (isdigit(*c)) {
                width = 0;
                while (isdigit(*c)) 
                    width = 10 * width + (*c++ - '0');
                if (width == 0)
                    return n;
            } else
                width = 1000;
            switch (*c) {
                case 'u':
                    MAYBE_STORE(uscan, unsigned);
                    break;
                case 'd':
                    MAYBE_STORE(dscan, int);
                    break;
                case 'i':
                    MAYBE_STORE(iscan, int);
                    break;
                case 'f':
                    MAYBE_STORE(fscan, float);
                    break;
                case 'e':
                case 'E':
                    MAYBE_STORE(escan, float);
                    break;
                case 's':
                    MAYBE_STORE(sscan, char*);
                    break;
                case 'c':
                    if (ignore)
                        fgetc(stream);
                    else {
                        *va_arg(ap, char*) = fgetc(stream);
                        n++;
                    }
                    break;            
                case '%':
                    if (fgetc(stream) != '%')
                        return n;
            }
        } else if (isspace(*c)) {
            char peek;
            while (isspace(peek = fgetc(stream)))
                ;
            ungetc(peek, stream);
        } else
            if (*c != fgetc(stream))
                return n;
    }
    return n;
}
int vscanf(const char* format, va_list ap) {
    return vfscanf(stdin, format, ap);
}
size_t fake_read(char* s, size_t n) {
    return 0;
}
int vsnscanf(const char* s, size_t n, const char* format, va_list ap) {
    FILE fake = {s, 0, 0, n, _READ, fake_read, NULL};;
    return vfscanf(&fake, format, ap);
}
int fscanf(FILE* stream, const char* format, ...) {
    int ret;
    va_list ap;
    va_start(ap, format);
    ret = vfscanf(stream, format, ap);
    va_end(ap);
    return ret;
}
int scanf(const char* format, ...) {
    int ret;
    va_list ap;
    va_start(ap, format);
    ret = vfscanf(stdin, format, ap);
    va_end(ap);
    return ret;
}
int snscanf(const char* s, size_t n, const char* format, ...) {
    int ret;
    va_list ap;
    va_start(ap, format);
    ret = vsnscanf(s, n, format, ap);
    va_end(ap);
    return ret;
}
void setbuf(FILE* stream, char* buffer) {
    if (buffer == NULL)
        stream->capacity = 1;
    stream->base = buffer;
}
int setvbuf(FILE* stream, char* buffer, int mode, size_t capacity) {
    switch (mode) {
        case _IOLBF:
            stream->flags |= _LINED;
        case _IOFBF:
            stream->capacity = capacity;
            break;
        case _IONBF:
            stream->capacity = 1;
            break;
        default:
            return EOF;
    }
    if (buffer == NULL)
        if ((stream->base = malloc(stream->capacity)) == NULL)
            return EOF;
    else
        stream->base = buffer;
    return _OK;
}