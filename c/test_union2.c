union file {
    char* start;
};

void foo() {
    union Foo {
        char c;
        int i;
    } myfoo;

    char c = myfoo.c;
    int i = myfoo.i;
}

void foo() {
    union Foo {
        char c;
        int i;
    } *myfoo;

    char c = myfoo->c;
    int i = myfoo->i;
}

char get1(char** c) {
    return *c;
}

char get1(union file* c) {
    return *c->start;
}