int g = 10, x;
char* s = "hello";
char c = 'c';
char a[] = "Hello";
char l[] = {'h','i'};

short data[] = {
    1234,
    650,
    333,
    6262,
    563
};

short *ptr;
short num = 6;

void loop1() {
    int i;
    for (i=0; i < sizeof data / sizeof data[0]; i++) {

    }
}
void loop2() {
    int i;
    for (i=0; i < sizeof data / sizeof(short); i++) {
        
    }
}