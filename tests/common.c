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

int foo() {
    int x, y, z, i, j, a[10];
    x = a[i];
    a[j] = y;
    z = a[i];
}