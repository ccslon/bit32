int inc(int n) {
    return n > 0? n - 1 : 0;
}

int foo(int n) {
    return n > 0? n-1 : n == 0? 0 : n;
}