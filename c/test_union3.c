int gets();
union Box {
    short num;
};
struct Truck {
    int type;
    union Box* boxes;
};

short gett() {
    struct Truck truck;
    return truck.boxes[gets()].num;
}