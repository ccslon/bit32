#include <stdio.h>

union IP4 {
	unsigned char c[4];
	unsigned int i;
};

int main() {
	union IP4 ip4;
	ip4.c[0] = 127;
	ip4.c[1] = 0;
	ip4.c[2] = 0;
	ip4.c[3] = 1;
	printf("%u.%u.%u.%u\n", ip4.c[0], ip4.c[1], ip4.c[2], ip4.c[3]);
	printf("%x\n", ip4.i);
	return 0;
}