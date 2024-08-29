typedef int* va_list;
#define va_start(ap, last) (ap = (int*)&(last)+4)
#define va_arg(ap, type) ((type)*ap++) // add cast
#define va_end(ap) (ap = (int*)0)
int print(const char* fmt, ...) {
    while (*fmt) {

    }
}

int sum(int base, int n, ...) {
    va_list nums;
    int i;
    va_start(nums, n);
    for (i = 0; i < n; i++) {
        base += va_arg(nums, int);
    }
    va_end(nums);
    return base;
}

int main() {
    print("%c", 'c');
    int s = sum(0, 5, 1, 2, 3, 4, 5);
}

