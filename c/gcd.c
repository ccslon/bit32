void printf(char*, ...);

int gcd(int a, int b) {
    if (b == 0) 
        return a;
    return gcd(b, a % b);
}
typedef struct {
    int num, den;
} frac;
void printFrac(frac *f) {
    if (f->den == 1)
        printf("%d", f->num);
    printf("%d/%d", f->num, f->den);
}
frac Frac(int num, int den) {
    int g = gcd(num, den);
    frac f = {num / g, den / g};
    return f;
}
frac add(frac* a, frac* b) {
    return Frac((a->num*b->den) + (b->num*a->den), a->den * b->den);
}
frac mul(frac* a, frac* b) {
    return Frac(a->num * b->num, a->den * b->den);
}

int main() {
    frac f = Frac(1,2);
    printFrac(&f);
}