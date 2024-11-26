#define N 5
int n = N;
#define MIN(a, b) ((a) <= (b) ? (a) : (b))

void foo(int x, int y) {
    int i = MIN(x, y) * (N + 1);
}