struct Cat {
    char* name;
    unsigned char age;        
};
struct Person {
    char* name;
    unsigned char age;
    struct Cat cat;    
};
int stack_int() {
    int ints[3] = {1,2,3};
    int ints2d[3][3] = {
        {1,2,3},
        {4,5,6},
        {7,8,9}
    };
}
void stack_cat() {
    struct Cat cat = {"Sam", 10};
}
void list_cat() {
    struct Cat cats[2] = {{"Sam", 10},{"Pippin", 6}};
}
void stack_person() {
    struct Person me = {"Colin", 27, {"Cloud", 15}};
}
void list_person() {
    struct Person people[2] = {{"Colin", 27, {"Cloud", 15}}, {"Nick", 24, {"Chuck", 15}}};
}