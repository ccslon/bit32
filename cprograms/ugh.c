int* foo(int);

int f() {
    *foo(3) = *foo(4);
}

int main() {
    int i = 9;
    i = *foo(3);
    *foo(4) = i;
    i = *foo(5) + 6;
    i = 7 + *foo(8);
}

void bar() {
    int a;
    a = *foo(1) + 2 + 3;
    a = 1 + *foo(2) + 3;
    a = 1 + 2 + *foo(3);
    a = *foo(1) + 2 + *foo(3);
}
void baz(void (*f)(int)) {
    (*f)(333);
}
void bax(int (*f)(int)) {
    int i = (*f)(444);
}


int accept(char*);

char factor() {
    char factor;
    if (factor = accept("num")) {
        return factor;
    } else if (factor = accept("var")) {
        return factor;
    } else if (accept("(")) {
        //expect(")");
    } else {
        //error
    }
}