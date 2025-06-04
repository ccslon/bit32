#define STDIO_H
#define NULL (void*)0
typedef unsigned size_t;
typedef struct {
    char* buffer;
    size_t read;
    size_t write;
    size_t size;
} FILE;
extern FILE* stdin;
extern FILE* stdout;
char fgetc(FILE* stream) {
    while (stream->read == stream->write)
        ;
    char c = stream->buffer[stream->read];
    stream->read = (stream->read + 1) % stream->size;
    return c;
}
#define getc() (fgetc(stdin))
char getchar() {
    while (stdin->read == stdin->write)
        ;
    char c = stdin->buffer[stdin->read];
    stdin->read = (stdin->read + 1) % stdin->size;
    return c;
}
char* fgets(char* s, size_t n, FILE* stream) {
    char c;
    char* cs = s;
    while (--n > 0 && (c = fgetc(stream)))
        *cs++ = c;
    *cs = '\0';
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
#define putc(c) (fputc((c), stdout))
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
void uprint(unsigned n) {
    if (n / 10)
        uprint(n / 10);
    putchar(n % 10 + '0');
}
void oprint(unsigned n) {
    if (n / 8)
        oprint(n / 8);
    putchar(n % 8 + '0');
}
void dprint(int n) {
    if (n < 0) {
        putchar('-');
        n = -n;
    }
    uprint(n);
}
void xprint(unsigned n, char uplo) {
    if (n / 16)
        xprint(n / 16, uplo);
    if (n % 16 > 9)
        putchar(n % 16 - 10 + uplo);
    else
        putchar(n % 16 + '0');        
}
void fprint(float f, char prec) {
    if (f < 0.0) {
        putchar('-');
        f = -f;
    }
    unsigned left = f;
    uprint(left);
    if (prec > 0) {
        putchar('.');
        float right = f - left;
        do {
            right *= 10.0;
            putchar((int)right + '0');
            right -= (int)right;
        } while (--prec > 0);
    }
}
void eprint(float f, char prec) {
    if (f < 0) {
        putchar('-');
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
    fprint(f, prec);
    putchar('e');
    dprint(exp);
}
#define va_arg(ap, type) (*(type*)ap++)
void printf(const char* format, ...) {
    int* ap;
    (ap = (int*)(&format + 1));
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
    (ap = (void*)0);
}
#undef va_arg