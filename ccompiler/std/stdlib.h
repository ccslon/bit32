#define STDLIB_H
#define NULL (void*)0
typedef unsigned size_t;
typedef struct {
    int quot;
    int rem;
} div_t;
div_t div(int num, int den) {
    div_t ans = {num / den, num % den};
    return ans;
}
int abs(int n) {
    if (n < 0) return -n;
    return n;
}
int bsearch(void* x, void* v, size_t size, size_t n, int (*cmp)(void*,void*)) {
    int low = 0;
    int mid;
    int high = n - 1;
    while (low <= high) {
        mid = low + (high - low) / 2;
        int cond = (*cmp)(x, &v[mid*size]);
        if (cond < 0)
            high = mid - 1;
        else if (cond > 0) 
            low = mid + 1;
        else
            return mid*size;
    }
    return -1;
}
void swap(void* v, size_t size, int i, int j) {
    size_t words = size / sizeof(int);
    char tail = size % sizeof(int);    
    int t;
    size_t k;
    for (k = 0; k < words; k += sizeof(int)) {
        t = *(int*)(v+i*size+k);
        *(int*)(v+i*size+k) = *(int*)(v+j*size+k);
        *(int*)(v+j*size+k) = t;
    }
    char c;
    for (c = 0; c < tail; c++) {
        t = *(char*)(v+i*size+k+c);
        *(char*)(v+i*size+k+c) = *(char*)(v+j*size+k+c);
        *(char*)(v+j*size+k+c) = t;
    }
}
void qsort(void* v, size_t size, int left, int right, int (*cmp)(void*,void*)) {
    int i, last;
    if (left >= right)
        return;
    swap(v, size, left, left + (right - left) / 2);
    last = left;
    for (i = left+1; i <= right; i++)
        if ((*cmp)(&v[i*size], &v[left*size]) < 0)
            swap(v, size, ++last, i);
    swap(v, size, left, last);
    qsort(v, size, left, last-1, cmp);
    qsort(v, size, last+1, right, cmp);
}
int next_rand = 0;
int rand() {
    next_rand = 1103515245 * next_rand + 12345; //mod 2^31 - 1
    return next_rand;
}
void srand(int seed) {
    next_rand = seed;
}
int atoi(const char* s) {
    int i, n = 0;
    for (i = 0; '0' <= s[i] && s[i] <= '9'; ++i)
        n = 10 * n + (s[i] - '0');
    return n;
}
float atof(const char* s) {
    float val, pow;
    int i = 0, sign;
    sign = s[i] == '-' ? -1 : 1;
    if (s[i] == '+' || s[i] == '-') 
        i++;
    for (val = 0.0; '0' <= s[i] && s[i] <= '9'; i++)
        val = 10.0 * val + (s[i] - '0');
    if (s[i] == '.')
        i++;
    for (pow = 1.0; '0' <= s[i] && s[i] <= '9'; i++) {
        val = 10.0 * val + (s[i] - '0');
        pow *= 10.0;
    }
    return sign * val / pow;
}

extern char stdheap[];
size_t heapindex = 0;
void* malloc(size_t bytes) {
    void* ptr = &stdheap[heapindex];
    heapindex += bytes;
    return ptr;
}
void free(void* p) {}
void* realloc(void* p, size_t size) {
    void* memcpy(void*, const void*, size_t);
    void* d = malloc(size);
    memcpy(d, p, size);
    free(p);
    return d;
}
void* calloc(size_t n, size_t size) {
    size_t bytes = n*size;
    size_t words = bytes / sizeof(int);
    size_t tail = bytes % sizeof(int);
    size_t i;
    void* p = malloc(bytes);
    for (i = 0; i < words; i++) 
        *(int*)(p+i) = 0;
    size_t c;
    for (c = 0; c < tail; c++)
        *(char*)(p+i+c) = 0;
    return p;
}