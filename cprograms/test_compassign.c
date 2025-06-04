struct Foo {
    int a, b;
};

void bar(struct Foo *foo) {
    foo->a *= 4;
}