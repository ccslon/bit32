union ufile {
    char* next;
};

struct sfile {
    //int header;
    char* next;
};
#define OUT 0x80000000
#define IN 0x80000001
char* out = (char*)OUT;
union ufile uout = (char*)OUT;
union ufile uin = (char*)IN;
struct sfile sout = {(char*)OUT};
int sfgetc(struct sfile* stream) {
    return *stream->next;
}
char ufgetc(union ufile* stream) {
    return *stream->next;
}
char fgetc(char** stream) {
    return **stream;
}
char sgetchar() {
    return *sout.next;
}
char ugetchar() {
    return *uin.next;
}
char getchar() {
    return *out;
}

int sfputc(char c, struct sfile* stream) {
    *stream->next = c;
    return 0;
}
int ufputc(char c, union ufile* stream) {
    *stream->next = c;
    return 0;
}

int sputchar(char c) {
    *sout.next = c;
    return 0;
}
int uputchar(char c) {
    *uout.next = c;
    return 0;
}
int putchar(char c) {
    *out = c;
    return 0;
}

int main() {
    //sputchar('A');
    //uputchar('B');
    //putchar('C');
    char c;
    while ((c = ufgetc(&uin)) != '\n') {
        if (c) {
            ufputc(c, &uout);
        }
    }
    return 0;
}