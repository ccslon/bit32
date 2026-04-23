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
char fgetc(FILE*);
#define getc() (fgetc(stdin))
char getchar();
char* fgets(char*, size_t, FILE*);
char* gets(char*, size_t);
int fputc(char, FILE*);
#define putc(c) (fputc((c), stdout))
int putchar(char c) ;
int fputs(const char*, FILE*);
int puts(const char*);
void uprint(unsigned);
void oprint(unsigned);
void dprint(int);
void xprint(unsigned, char);
void fprint(float, char);
void eprint(float, char);
void printf(const char*, ...);