void multi() {
    ints:
    int i1 = 3;
    int i2 = 10;
    floats:
    float f1 = 1.5;
    float f2 = 3.5; 
    convert_ints:
    int i3 = i1 + i2;
    i3 = f1 - i2;
    i3 = i1 * f2;
    i3 = f1 / f2; 
    convert_floats:
    float f3 = i1 + i2;
    f3 = f1 - i2;
    f3 = i1 * f2;
    f3 = f1 / f2;
    i3 = i1 + i2 * 4;
    f3 = i1 + i2 * 4;
}