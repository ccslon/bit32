
typedef struct {
    char* name;
    int age;
} Cat;
int foo() {
    Cat cat;
    cat.name = "Cloud";
    Cat cat2;
}

void bar(void* ptr) {
    Cat* cat = (Cat*)ptr;
}
