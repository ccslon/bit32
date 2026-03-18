int strlen(char*);
char* strrev(char* s) {
    int front, back;
    for (front = 0, back = strlen(s)-1; front < back; front++, back--) {
        char temp = s[front];
        s[front] = s[back];
        s[back] = temp;
    }
    return s;
}