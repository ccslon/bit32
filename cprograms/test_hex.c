#include <stdio.h>

int main() {
    unsigned char i;
	for (i = 0; i < 0x100; i++)
		printf("%x %d\n", i, i);
	return 0;
}