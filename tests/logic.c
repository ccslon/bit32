void baz();
int foo(int a, int b) {
    int n = a && b;
    do {
        baz();
    } while (a && b);
    if (a && b) {
        return 100;
    }
}
int bar(int a, int b) {
    int n = a || b;
    do {
        baz();
    } while (a || b);
    if (a || b) {
        return 100;
    }
}
int no(int a) {
    int n = !a;
    do {
        baz();
    } while (!a);
    if (!a) {
        return 100;
    }
}