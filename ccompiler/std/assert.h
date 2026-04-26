#define ASSERT_H
#ifdef NDEBUG
#include <stdio.h>
void abort();
#define __ASSERT_H_STR(s) #s
#define __ASSERT_H_STRX(x) __ASSERT_H_STR(x)
#define assert(test) do { \
    if (!(test)) { \
        puts(__FILE__ ": " __ASSERT_H_STRX(__LINE__) ": Assert error " #test); \
        abort(); \
    } \
} while (0)
#else
#define assert(_) (void)0
#endif