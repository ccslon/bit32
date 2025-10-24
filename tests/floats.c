float myfloat = 1.5;
float foo(float a, float b) {
    return a + b;
}
void func1() {
    float f = 1.5;
    foo(f, -1.5);
}
float half1() {
    return 1 / 2;
}
float half2() {
    return 1.0 / 2;
}
float half3() {
    return (float)1 / 2;
}
void test(int i, float f) {
    int half1 = i / 2;
    int half2 = i / 2.0;
    float half3 = f / 2;
    float half4 = f / 2.0;
}
struct Foo {
    float f;
    int i;
};
void func2() {
    struct Foo foo;
    foo.i = 1.5;
    int i = foo.f;
    int x = foo.i + foo.f;
}