//#include <stdio.h>

typedef struct {
	float x;
	float y;
	float z;
} Point3D;
void foo(int a, int b, ...) {
	
}

int next = 0;
int rand() {
    next = (1103515245 * next + 12345) % 4294967295; //mod 2^31 - 1
    return next;
}

int main() {
	int i = rand();
	//Point3D p = {1,2,3};
	//foo(33, 44, 55, 66, 77);
    // fputs("Hello", &stdout);
    // fputc('f', &stdout);
    // putchar('c');
    // putchar('\n');
    // puts("Hello");
    // dprint(34);
    // printf("Hello World\n");
    // printf("%d", 123);
    //fprint(1.5);
	
}