#include <setjmp.h>

void out(char);

jmp_buf env;

int div(int n, int d) {
    if (d == 0) longjmp(env, -1);
    return n / d;

}

int main() {
    int a, b, c;
    if (setjmp(env) == 0) {
        a = 5;
        b = 2*a;
        c = div(1, 0);
        a = b + c;
        return 0;
    } else {
        out('e');
        out('r');
        out('r');
        return 1;
    }
}