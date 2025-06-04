int foo(int a, int b, int c, int d) {
    return a + b + c + d;
}

int main() {
    int i;
    i += foo(2,3,4,5);
}

void loopa(int *a, int *b) {
    int i = 0;
    while(a[i] = b[i]) i++;
}

void loopp(int *p, int *q) {
    while(*p++ = *q++) ;
}