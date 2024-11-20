typedef union {
    char* next;
} FILE;

FILE stdout = (char*)0x80000000;

void fputc(char c, FILE* stream) {
    *stream->next = c;
}

int main() {
    fputc('H', &stdout);
    return 0;
}