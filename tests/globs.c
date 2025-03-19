
typedef struct _Owner_ {
    char* name;
    unsigned char age;
} Owner;
typedef struct _Cat_ {
    char* name;
    unsigned char age;
    Owner* owner;
} Cat;
struct Foo {
    char c;
    short s;
    int i;
} foo = {1,2,3};
int globs[3] = {1,2,3};
Owner owners[2] = {{"Colin",34}, {"Mom", 21}};
Cat cats[3];
char* name = "Cats Ya!";
int num = 69, lol = 420, lmao;
void print_cat(Cat* cat) {
    char* store = name;
    int n = num;
    char* mycat = cat->name;    
    int age = cat->age;
    char* owner = cat->owner->name;
    num = 420;
}
int main() {
    Cat* cat1 = &cats[0];
    cat1->name = "Cloud";
    cat1->age = 10;
    cat1->owner = &owners[0];
    print_cat(cat1);
    return 0;
}