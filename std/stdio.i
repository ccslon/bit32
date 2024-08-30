
typedef int* FILE;
FILE stdout = (int*)0x80000000;
FILE stdin = (int*)0x80000001;
char fgetc(FILE* stream) {
    return **stream;
}

char getchar() {
    return *stdin;
}
char* fgets(char* s, int n, FILE* stream) {
    char c;
    char* cs = s;
    while (--n > 0 && (c = fgetc(stream))) 
        if ((*cs++ = c) == '\n')
            break;
    *cs = '\0';
    return s;
}
















































































