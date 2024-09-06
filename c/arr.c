struct Cat {
    char* name;
    unsigned char age;        
};
struct Person {
    char* name;
    unsigned char age;
    struct Cat cat;    
};

int main() {
    //struct Person me = {"Colin", 27, {"Cloud", 15}};
    int ints[3] = {1,2,3};
    int ints2d[3][3] = {
        {1,2,3},
        {4,5,6},
        {7,8,9}
    };
    // struct Cat cats[2] = {{"Sam", 10},{"Pippin", 6}};
    // int ints[3];
    // int ints2d[3][3];
    // ints2d[1][1] = 5;
    // int yours = ints[1];
    // int mine = ints2d[1][1];
}

/*

main:
    add A, FP, 0
    ld B, =.S0 ; "Colin"
    ld [A, 0], B
    mov B, 27
    ld [A, 4], B
    add A, A, 5
    ld B, =.S1 ; "Cloud"
    ld [A, 0] B
    mov B, 15
    ld [A, 4], B

    ; struct Cat cats[2] = {{"Sam", 10},{"Pippin", 6}};

*/