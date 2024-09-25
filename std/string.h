typedef unsigned int size_t;
int strlen(const char* s) {
    int l = 0;
    while (*s != '\0') {
        s++;
        l++;
    }
    return l;
}
char* strcpy(char* s, const char* t) {
    int i;
    for (i = 0; (s[i] = t[i]) != '\0'; i++) 
        ;
    return s;
}
char* strcat(char* s, const char* t) {
    int i, j;
    i = j = 0;
    while (s[i] != '\0') 
        i++;
    while((s[i++] = t[j++]) != '\0')
        ;
}
char* strrev(char* s) {
    unsigned int front = 0, back = strlen(s) - 1;
    while (front < back) {
        char temp = s[front];
        s[front] = s[back];
        s[back] = temp;
        front++;
        back--;
    }
    return s;
}
int strcmp(const char* s, const char* t) {
    int i;
    for (i = 0; s[i] == t[i]; i++)
        if (s[i] == '\0')
            return 0;
    return s[i] - t[i];
}
char* strchr(const char* s, char c) {

}
char* strrchr(const char* s, char c) {

}
void* memcpy(void* s, const void* t, int n) {
    size_t i;
    for (i = 0; i < n; i++) 
        *(char*)(s+i) = *(char*)(t+i);
    return s;
}
int memcmp(const void* s, const void* t, int n) {
    size_t i;
    for (i = 0; i < n; i++)
        if (*(char*)(s+i) != *(char*)(t+i))
            return *(char*)(s+i) - *(char*)(t+i);
    return 1;
}