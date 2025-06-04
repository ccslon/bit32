int foo(int a, int b) {
    return a + b * b;
}
int baz(int a, int b, int c, int d) {
    return (a + b) * (c * d);
}
int bay(int c) {
    return 2*c;
}
void b() {
    //int a = foo(3,baz(4, 5, 6, 7 + 8 * 9));
    //int b = foo(2, bay(3));
    int c = foo(3,4) + 5;

}