int sumfs(int n, int (*f[])(int)) {
    int s = 0, i;
    for (i = 0; i < n; ++i) {
        s += (*f[i])(i);
    }
    return s;
}

int sqr(int n) {
    return n * n;
}

int sum(int n, int (*f)(int)) {
    int sum = 0, i;
    for (i = 0; i < n; i++) {
        sum += (*f)(i);
    }
    return sum;
}

#define FUNCS_LENGTH 4
int main() {
    int (*funcs[FUNCS_LENGTH])(int) = {sqr, sqr, sqr, sqr};
    int result = sumfs(FUNCS_LENGTH, funcs);
    return sum(5, sqr);
}