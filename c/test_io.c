union file {
    char* next;
};
typedef union file FILE;
FILE stdout = (char*)0x80000000;
FILE stdin = (char*)0x80000001;
char fgetc(FILE* stream) {
    return *stream->next;
}
char getchar() {
    return *stdin.next;
}
int fputc(char c, FILE* stream) {
    *stream->next = c;
    return 0;
}
int putchar(char c) {
    *stdout.next = c;
    return 0;
}