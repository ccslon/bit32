#define STDIN_SIZE 32
typedef struct {
    char* buffer;
    unsigned read;
    unsigned write;
    unsigned size;
} FILE;
char stdin_buffer[STDIN_SIZE];
FILE stdin = {stdin_buffer, 0, 0, 32};

extern char in();
extern void out(char);
#define INC(var) ((var) = ((var) + 1) % STDIN_SIZE)
#define DEC(var) ((var) = (var) == 0 ? STDIN_SIZE - 1 : (var)--)
void interrupt() {
    char i;
    char c;
    for (i = 0; i < 8 && (c = in()) != '\0'; i++)  {
        out(c);
        switch (c) {
            case '\n':
                stdin[stdin_write] = '\0';
                INC(stdin_write);
                break;
            case '\b':
                DEC(stdin_write);
                break;
            default:
                stdin[stdin_write] = c;
                INC(stdin_write)
        }
    }
}