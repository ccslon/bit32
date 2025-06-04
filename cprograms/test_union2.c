union file {
    char* start;
};

void foo() {
    union Foo {
        char c;
        int i;
    } myfoo;

    char c = myfoo.c;
    int i = myfoo.i;
}

void foo() {
    union Foo {
        char c;
        int i;
    } *myfoo;

    char c = myfoo->c;
    int i = myfoo->i;
}

char get1(char** c) {
    return *c;
}

char get1(union file* c) {
    return *c->start;
}

union Box {
    short num;
};

short gets(short* s) {
    return *s;
}

short gets(union Box* s) {
    return s->num;
}
short gets() {
    short s;
    return s;
}

short gets() {
    union Box s;
    return s.num;
}

struct Arm {
    int type;
    union Box box;
};

short geta() {
    struct Arm arm;
    return arm.box.num;
}
short geta(struct Arm *arm) {
    return arm->box.num;
}

struct Rec {
    int type;
    union Box *box;
};

short getr() {
    struct Rec rec;
    return rec.box->num;
}

short getr(struct Rec *rec) {
    return rec->box->num;
}

short foo() {
    union Box {
        short s;
    } foo[5];
    return foo[4].s;
}

short foo() {
    union Box {
        short s;
    }* foo[5];
    return foo[4]->s;
}

struct Truck {
    int type;
    union Box* boxes;
};

short gett() {
    struct Truck truck;
    return truck.boxes[gets()].num;
}