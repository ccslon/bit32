typedef struct {
    char* data;
    int read;
    int write;
} Buffer;

int main() {
    int a, b, c;
    b = a + a;
    c = (a + b) * (a + b);
    Buffer *buf;
    buf->data[buf->write] = 'c';
    buf->data[buf->write++] = '!';
}

extern volatile int vglob;

void test_volatile() {
    volatile const int a;
    int b, c;
    b = a + a;
    c = (a + b) * (a + b);
    b = vglob + vglob;
    //a = b; //should fail
}

int foo() {
    int x, y, z, i, j, a[10];
    x = a[i];
    a[j] = y;
    z = a[i];
}

