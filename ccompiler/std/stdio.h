#define STDIO_H
#define NULL (void*)0
#define EOF -1
typedef unsigned size_t;
typedef struct {
    char* buffer;
    size_t read;
    size_t write;
    size_t size;
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
int fputs(const char*, FILE*);
int puts(const char*);
int ungetc(char, FILE*);
#include "va_list.h"
int vfprintf(FILE*, const char*, va_list);
int vprintf(const char*, va_list);
int vsnprintf(char*, size_t, const char*, va_list);
int fprintf(FILE*, const char*, ...);
int printf(const char*, ...);
int snprintf(char*, size_t, const char*, ...);
int vfscanf(FILE*, const char*, va_list);
int vscanf(const char*, va_list);
int vsscanf(const char*, const char*, va_list);
int fscanf(FILE*, const char*, ...);
int scanf(const char*, ...);
int sscanf(const char*, const char*, ...);