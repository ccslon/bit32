char* out = 0x80000000;

char func1();

int main() {
    *out = '0' + func1();
}

char func1() {
    char i;
    for (i = 0; i < 10; i++) {

    }
    for (i; i != 5; i--) {

    }
    if (i >= 4) {
        i++;
    }
    return i;
}