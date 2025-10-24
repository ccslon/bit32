float f = (float)(1 << 5);
int g = 1 << 5;
float half = 0.5;
void foo();
int main() {
    int i = 1 << 7;
    float j = (float)(1 << 7);
    float k = -(1.0/2.0);
    int l = ++3;
    int m = l + 3++;
    int n = !(2+2);
    int m = 2 > 1;
    int o = 1 || 0;
    int p = 3 ? m : n;
    int q = 3 ? 4 : 5;
    char* r = 0 ? "abc" : 1 ? "def" : "xyz";
    int s = "foo" ? 2 : 3;
    int t = "" ? 4 : 5;
}
void test_loops() {
    while (1) {
        foo();
    }
    while (0) {
        foo();
    }
    int i, p, q;
    for (i=0;1;i++) {
        p = q++;
        foo();
    }
    do {
        foo();
    } while(0);
}
void test_ifs() {
    int q;
    if (0) {
        foo();
    } else if (1) {
        q++;
    } else {
        q = 10;
    }
}