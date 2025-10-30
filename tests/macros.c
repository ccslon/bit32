#define N 5
int n = N;
#
#include "inc1.c"
#define MIN(a, b) ((a) <= (b) ? (a) : (b))
int bar(int n);
#define NULL (void*)0
    //lol
#define FOO() BAR
FOO()BAZ
#undef FOO
FOO()
#define TABLESIZE BUFSIZE
#define BUFSIZE 1024
TABLESIZE
"hello" "world"
#define BAZ( ) (i++)
print("Helo worl")
a/*lol*/b
#define xstr(s) str(s)
#define str(s) #s
str(N)
xstr(N)
a /*lol*/   b
void foo(int x, int y) {
    int i = MIN(bar(x), bar(y)) * (N + 1);
    int i = MIN(x, y) * (N + 1);
    char* ptr = NULL;
}
#define CAST(type, x) ((type)(x))
char* buf = CAST(char*, 0x8000);
#define say(n) (printf(#n " has been said"))
say(45)
#define binary(a, op, b) ((a) op (b))
int o = binary(h, +, j+t);