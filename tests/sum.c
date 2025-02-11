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

int main() {
    return sum(5, sqr);
}