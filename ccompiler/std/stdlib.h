#define STDLIB_H
#define NULL (void*)0
typedef unsigned size_t;
typedef struct {
    int quot;
    int rem;
} div_t;
div_t div(int, int);
int abs(int);
int bsearch(void*, void*, size_t, size_t, int (*)(void*,void*));
void swap(void*, size_t, int, int);
void qsort(void*, size_t, int, int, int (*)(void*,void*));;
int rand();
void srand(int);
int atoi(const char*);
float atof(const char*);
void* malloc(size_t);
void free(void*);
void* realloc(void*, size_t);
void* calloc(size_t, size_t);