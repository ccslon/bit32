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
    struct Person me = {"Colin", 27, {"Cloud", 15}};
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
*/