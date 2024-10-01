#define NULL (void*)0
typedef unsigned size_t;
typedef struct _div_t_ {
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
// int bsearch(int x, int* v, int n, int (*cmp)(int, int)) {
//     int low = 0;
//     int mid;
//     int high = n - 1;
//     while (low <= high) {
//         mid = low + (high - low) / 2;
//         int cond = (*cmp)(x, v[mid]);
//         if (cond < 0)
//             high = mid - 1;
//         else if (cond > 0) 
//             low = mid + 1;
//         else
//             return mid;
//     }
//     return -1;
// }
int bsearch(void* x, void* v[], unsigned size, unsigned n, int (*cmp)(void*,void*)) {
    int low = 0;
    int mid;
    int high = n - 1;
    while (low <= high) {
        mid = low + (high - low) / 2;
        int cond = (*cmp)(x, v[mid*size]);
        if (cond < 0)
            high = mid - 1;
        else if (cond > 0) 
            low = mid + 1;
        else
            return mid*size;
    }
    return -1;
}
void swap(void* v, unsigned size, int i, int j) {
    char t;
    unsigned k;
    for (k = 0; k < size; k++) {
        t = *(char*)(v+i*size+k);
        *(char*)(v+i*size+k) = *(char*)(v+j*size+k);
        *(char*)(v+j*size+k) = t;
    }
}
void qsort(void* v, unsigned size, int left, int right, int (*cmp)(void*,void*)) {
    int i, last;
    if (left >= right)
        return;
    int mid = left + (right - left) / 2;
    swap(v, size, left, mid);
    last = left;
    for (i = left+1; i <= right; i++)
        if ((*cmp)(&v[i*size], &v[left*size]) < 0)
            swap(v, size, ++last, i);
    swap(v, size, left, last);
    qsort(v, size, left, last-1, cmp);
    qsort(v, size, last+1, right, cmp);
}
int next = 0;
int rand() {
    next = 1103515245 * next + 12345; //mod 2^31 - 1
    return next;
}
void srand(int seed) {
    next = seed;
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

#define HEAPLEN 1024
char heap[HEAPLEN];
char* heapindex = 0;
void* malloc(int bytes) {
    if (heapindex >= HEAPLEN) 
        return NULL;
    void* p = &heap[heapindex];
    heapindex += bytes;
    return p;
}
void free(void* p) {}
void* realloc(void* p, int size) {
    void* memcpy(void*, const void*, size_t);
    void* d = malloc(size);
    //memcpy(d, p, size);
    free(p);
    return d;
}
void* calloc(int n, int size) {
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
/*
struct header {
    struct header *next;
    int size;
};
typedef struct header Header;
Header *freep = NULL;
Header base;
void free(void* ptr) {
    Header *bp, *p;
    bp = (Header*)ptr - 1;
    for (p = freep; !(p < bp && bp < p->next); p = p->next)
        if (p >= p->next && (p < bp || bp <p->next))
            break;
    if (bp + bp->size == p->next) {
        bp->size += p->next->size;
        bp->next = p->next->next;
    } else 
        bp->next = p->next;
    if (p + p->next == bp) {
        p->size += bp->size;
        p->next = bp->next;
    } else
        p->next = bp;
    freep = p;
}
void* malloc(int size) {
    Header *p, *prevp;
    if ((prevp = freep) == NULL) {
        base.next = freep = prevp = &base;
        base.size = 0;
    }
    for (p = prevp->next; 1; prevp = p, p = p->next) {
        if (p->size >= size) {
            if (p->size == size)
                prevp->next = p->next;
            else {
                p->size -= size;
                p += p->size;
                p->size = size;
            }
            freep = prevp;
            return (void*)(p+1);
        }
    }
}
*/