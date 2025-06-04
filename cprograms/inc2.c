// void printf(char*,...);
// void bar(char* f, ...) {
//     char* ap;
//     (ap = (&f)+4);
//     if (*f == 'd') 
//         printf("%d\n", (*((int*)ap)++));
// }

// int main() {
//     bar("d", 123456);
// }
//#include "preproc.c"

char* lol = CAST(char*, 0x80000000);