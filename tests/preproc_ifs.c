#define FOO 5

// #if defined FOO
// #define BAR -2
// #if FOO >= 5 && BAR > - 3 
// int maybe = 456
// #endif
// int yes = 40000
// #else
// #define BAR 34
// int no = 1234
// #endif
#define BAR 0
#if BAR == 0
#define BAZ 9
#elif BAR == 1
#define BAZ 8
#elif BAR == 2
#define BAZ 7
#else
#define BAZ 6
#endif
int bar = BAZ

int main() {
    int i;
    for (i=0; i < BAR; i++) {

    }
}


/*
Dead block
Nested
Already True'd
Level

*/