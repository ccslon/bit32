#define NULL (void*)0
typedef int* FILE;
FILE stdout = (int*)0x80000000;
FILE stdin = (int*)0x80000001;
char fgetc(FILE* stream) {
    return **stream;
}
#define getc() (fgetc(&stdin))
char getchar() {
    return *stdin;
}
char* fgets(char* s, int n, FILE* stream) {
    char c;
    char* cs = s;
    while (--n > 0 && (c = fgetc(stream))) // "enter"
        if ((*cs++ = c) == '\n')
            break;
    *cs = '\0';
    return s;
}
char* gets(char* s) {
    return fgets(s, 0xff, &stdin);
}
int fputc(char c, FILE* stream) {
    **stream = c;
    return 0;
}
#define putc(c) (fputc(c, &stdout))
int putchar(char c) {
    *stdout = c;
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
    fputs(s, &stdout);
    putchar('\n');
    return 0;
}
void uprint(unsigned int n) {
    if (n / 10)
        uprint(n / 10);
    putchar(n % 10 + '0');
}
void dprint(int n) {
    if (n < 0) {
        putchar('-');
        n = -n;
    }
    uprint(n);
}
void xprint(unsigned int n, char uplo) {
    if (n / 16)
        xprint(n / 16, uplo);
    if (n % 16 > 9) 
        putchar(n % 16 - 10 + uplo);
    else
        putchar(n % 16 + '0');
}
void fprint(float f, char prec) {
    if (f < 0) {
        putchar('-');
        f = -f;
    }
    int left = f;
    dprint(left);
    putchar('.');
    int p;
    for (p = 1; prec > 0; --prec) p *= 10;
    int right = (f - left) * p;
    dprint(right);    
}
void printf(const char* format, ...) {
    int* ap;
    (ap = (int*)&(format)+4);
    const char* c;
    for (c = format; *c; c++) {
        if (*c == '%') {
            switch (*++c) {
                case 'u': {
                    uprint(((unsigned int)*ap++));
                    break;
                }
                case 'i': ;
                case 'd': {
                    dprint(((int)*ap++));
                    break;
                }
                case 'x': {
                    xprint(((int)*ap++), 'a');
                    break;
                }
                case 'X': {
                    xprint(((int)*ap++), 'A');
                    break;
                }
                case 's': {
                    printf(((char*)*ap++));
                    break;
                }
                case 'c': {
                    putchar(((char)*ap++));
                    break;
                }
                default: putchar(*c);
            }
        } else {
            putchar(*c);
        }
    }
    (ap = (int*)0);
}