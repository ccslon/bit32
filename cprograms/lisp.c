#define LINE_LENGTH 32

typedef unsigned size_t;
char in();
void out(char);

char buffer[LINE_LENGTH];

size_t strlen(const char* s) {
    size_t l = 0;
    while (s[l] != '\0')
        l++;
    return l;
}

int strcmp(const char* s, const char* t, size_t size) {
    size_t i;
    for (i = 0; i < size && s[i] == t[i]; i++)
        if (s[i] == '\0')
            return 0;
    return s[i] - t[i];
}

int get_line(char* s, size_t size) {
    char c;
    size_t i = 0;
    while ((c = in()) != '\n') {
        if (c) {
            if (c == '\b') {
                out(c);
                if (i > 0)
                    i--;
            } else if (i < size-1) {
                out(c);
                s[i++] = c;
            }
        }
    }    
    s[i] = '\0';
    return i;
}

void print(char* s) {
    size_t i;
    for (i = 0; s[i] != '\0'; i++) {
        out(s[i]);
    }
}

int main() {
    buffer[0] = '\0';
    while (1) {
        get_line(buffer, LINE_LENGTH);
        if (strcmp(buffer, "quit", LINE_LENGTH) == 0) {
            print("\nGoodbye\n");
            break;
        } else if (buffer[0] == '(') {
            //eval
        } else {
            print("\nUnknown command\n");
        }
    }
    return 0;
}