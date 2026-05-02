int n = 3;
int next_int() {
    static int n;
    return n++;
}

static float f;

int main() {
    if (n > 10) return n;
    return 0;
}