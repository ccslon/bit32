#define STDDEF_H
typedef int ptrdiff_t;
typedef unsigned size_t;
#define NULL (void*)0
#define OFFSETOF(type, attr) ((size_t)&(((type *)0)->attr))