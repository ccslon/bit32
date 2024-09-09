#include <stdio.h>

int main() {
    unsigned char i;
	for (i = 0xfa; i < 0xff; i++)
		printf("%x\n", i);
	return 0;
}