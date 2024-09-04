#include <stdio.h>

typedef struct _Owner_ {
    char* name;
    int phone;
} Owner;
typedef struct _Cat_ {
    char* name;
    unsigned char age;
    Owner* owner;
} Cat;
void print_cat(Cat* cat) {    
    printf("%s %u\n", cat->name, cat->age);
    printf("%s\n", cat->owner->name);
}
Cat make_cat(char* name, unsigned char age, Owner* owner) {
    Cat cat;
    cat.name = name;
    cat.age = age;
    cat.owner = owner;
    return cat;
}
//Cats
int main() {
    Owner me;
    me.name = "Colin";
    me.phone = 2489788876;
    Cat cat1;

    cat1.name = "Cloud";
    cat1.age = 10;
    cat1.owner = &me;
    print_cat(&cat1);
    Cat cat2;
    cat2 = make_cat("Chuck",15,&me);
    print_cat(&cat2);
    return 0;
}