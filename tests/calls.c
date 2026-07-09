int baz(int y, int* z) {
    return y * *z;
}
int bar(int x, int y) {
    return x*y;
}
int foo(int x, int y, int z) {
    return bar(x, y) + baz(y, &z) + bar(-3, 4);
}

int test(int a, int b, int c) {
    int x = foo(a, bar(b, c+a), c);
    int y = foo(bar(a+a, 1), b, c);
    int z = foo(a, b, baz(3, &c));
}
