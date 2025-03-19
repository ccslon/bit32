void bar(int n);
void foo1(int n) {
    if (n == 1) {
        bar(100);
    }
}
void foo2(int n) {
    if (n == 1) {
        bar(100);
    } else if (n > 100) {
        bar(-1);
    }
}
void foo2_5(int n) {
    if (n == 1) {
        bar(100);
    } else {
        if (n > 100) {
            bar(-1);
        }        
    }
}
void foo3(int n) {
    if (n == 1) {
        bar(100);
    } else {
        bar(0);     
    }
}
void foo4(int n) {
    if (n == 1) {
        bar(100);
    } else if (n > 100) {
        bar(-1);
    } else {
        bar(0);
    }
}