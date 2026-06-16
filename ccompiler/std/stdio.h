#include "va_list.h"
#define STDIO_H
#define NULL (void*)0
#define EOF (-1)
#define BUFSIZ 256
#define MAX_OPEN 32
#define feof(s) (((s)->flags & _EOF) != 0)
#define ferror(s) (((s)->flags & _ERROR) != 0)
#define clearerr(s) ((s)->flags &= ~_ERROR)
typedef unsigned size_t;
enum mode {
    _IOFBF,
    _IOLBF,
    _IONBF
};
typedef struct {
    char* base;
    size_t index;
    size_t size;
    size_t capacity;
    char flags;
    size_t (*read)(char*, size_t);
    size_t (*write)(const char*, size_t);
} FILE;
extern FILE* stdin;
extern FILE* stdout;
extern FILE* stderr;
char fgetc(FILE*);
#define getc() (fgetc(stdin))
char getchar();
char* fgets(char*, size_t, FILE*);
char* gets(char*, size_t);
int fputc(char, FILE*);
#define putc(c) (fputc((c), stdout))
int putchar(char c) ;
int fputs(const char*, size_t, FILE*);
int puts(const char*);
int ungetc(char, FILE*);
int vfprintf(FILE*, const char*, va_list);
int vprintf(const char*, va_list);
int vsnprintf(char*, size_t, const char*, va_list);
int fprintf(FILE*, const char*, ...);
int printf(const char*, ...);
int snprintf(char*, size_t, const char*, ...);
int vfscanf(FILE*, const char*, va_list);
int vscanf(const char*, va_list);
int vsnscanf(const char*, size_t, const char*, va_list);
int fscanf(FILE*, const char*, ...);
int scanf(const char*, ...);
int snscanf(const char*, size_t, const char*, ...);
int fflush(FILE*);
void setbuf(FILE*, char*);
int setvbuf( FILE*, char*, int, size_t);
/*
fread
fwrite
*/
