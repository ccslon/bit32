short data[] = {
    1234,
    650,
    333,
    6262,
    563
};

short *ptr;
short num = 6;

typedef struct {
    int i;
    short s;
    char c;
} Thing;

void* alloc(int size);
void foo() {
    Thing* thing = alloc(sizeof(Thing));
}

void loop1() {
    int i, s = 0;
    for (i=0; i < sizeof data / sizeof data[0]; i++) {
        s += data[i];
    }
}
void loop2() {
    int i, s = 0;
    for (i=0; i < sizeof data / sizeof(short); i++) {
        s += data[i];
    }
}