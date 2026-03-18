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
char fgetc(FILE* stream);
#define getc() (fgetc(stdin))
char getchar();
char* fgets(char*, size_t, FILE*);
char* gets(char*, size_t);
int fputc(char c, FILE* stream);
#define putc(c) (fputc((c), stdout))
int putchar(char c) ;
int fputs(const char* s, FILE* stream);
int puts(const char* s);
void uprint(unsigned n);
void oprint(unsigned n);
void dprint(int n);
void xprint(unsigned n, char uplo);
void fprint(float f, char prec);
void eprint(float f, char prec);
void printf(const char* format, ...);