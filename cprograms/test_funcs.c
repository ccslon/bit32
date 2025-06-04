struct Cat {
    char* name;
    int age;
    char* (*get_name)(struct Cat*);
};

int foo() {
    struct Cat cat;
    (*cat.get_name)(&cat);
}

// void iter(int array[], void (*f)(void*)) {
//     (*f)(array);
// }
// void print(void* s) {
    
// }

// int main() {
//     int a[8];
//     iter(a, print);
//     return 0;
// }