#define ITERATIONS 10

unsigned int factorial(unsigned int n) {
    unsigned int factorial;
    for (factorial = 1; n > 0; n--) {
        factorial *= n;
    }
    return factorial;
}

float sum(float x, float (*f)(float, unsigned int)) {
    float sum = 0;
    unsigned int n;
    for (n = 0; n < ITERATIONS; n++) {
        sum += (*f)(x, n);
    }
    return sum;
}

float pow(float base, unsigned int exp) {
    float pow = 1;
    while (exp > 0) {
        pow *= base;
        exp--;
    }
    return pow;
}

float sin(float t) {
    float sin = 0;
    unsigned int n;
    for (n = 0; n < ITERATIONS; n++) {
        sin += (pow(-1,n) / factorial(2*n + 1)) * pow(t, 2*n + 1);
    }
    return sin;
}