union IP {
    int i;
    char c[4];
};

void func1() {
    union IP ip;
    ip.c[0] = 127;
    ip.c[1] = 0;
    ip.c[2] = 0;
    ip.c[3] = 1;
    int i = ip.i;
}