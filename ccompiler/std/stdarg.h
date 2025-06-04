#define STDARG_H
typedef int* va_list;
#define va_start(ap, last) (ap = (va_list)(&last + 1))
#define va_arg(ap, type) (*(type*)ap++)
#define va_end(ap) (ap = (void*)0)
