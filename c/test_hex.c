#include <stdio.h>

int main() {
    unsigned char i;
	for (i = 1; i < 100; i++)
		printf("%x %d\n", i, i);
	return 0;
}