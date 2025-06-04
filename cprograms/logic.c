void baz();
int foo(int a, int b) {
    int n = a < b && b > 0;
    // do {
    //     baz();
    // } while (n = a < b && b > 0);
    if (a < b && b > 0) {
        return 100;
    }
}
int bar(int a, int b) {
    int n = a < b || b > 0;
    // do {
    //     baz();
    // } while (a < b || b > 0);
    if (a < b || b > 0) {
        return 100;
    }
}
