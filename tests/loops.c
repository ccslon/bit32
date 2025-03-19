int foo();
int bar();
void while_loop() {
    while (foo()) {
        if (bar()) {
            continue;
        } else {
            break;            
        }
    }
}    
void for_loop() {
    int i;
    for (i = 0; foo(); i++) {
        if (bar()) {
            continue;
        } else {
            break;
        }
    }
}