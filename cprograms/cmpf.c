void out(char);

void foo(float a, float b) {
    if (a > b){
        out('Y');
    } else {
        out('N');
    }
}

int main() {
    foo(1.05, 1.5);
}