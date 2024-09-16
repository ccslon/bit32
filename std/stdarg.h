typedef int* va_list;
#define va_start(ap, last) (ap = (int*)&(last)+4)
#define va_arg(ap, type) ((type)*ap++) // add cast
#define va_end(ap) (ap = (int*)0)