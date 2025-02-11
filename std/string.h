#define STRING_H
typedef unsigned size_t;
size_t strlen(const char* s) {
    size_t l = 0;
    while (s[l] != '\0')
        l++;
    return l;
}
char* strcpy(char* s, const char* t) {
    size_t i;
    for (i = 0; (s[i] = t[i]) != '\0'; i++) 
        ;
    return s;
}
char* strncpy(char* s, const char* t, size_t n) {
    size_t i;
    for (i = 0; i < n && (s[i] = t[i]) != '\0'; i++) 
        ;
    return s;
}
char* strdup(char* s) {
    void* malloc(unsigned);
    char* p = malloc(strlen(s)+1);
    if (p != (void*)0)
        strncpy(p, s, strlen(s)+1);
    return p;
}
char* strcat(char* s, const char* t) {
    size_t i = strlen(s), j = 0;
    while((s[i++] = t[j++]) != '\0')
        ;
    return s;
}
char* strrev(char* s) {
    size_t front, back;
    for (front = 0, back = strlen(s)-1; front < back; front++, back--) {
        char temp = s[front];
        s[front] = s[back];
        s[back] = temp;
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
int strncmp(const char* s, const char* t, size_t n) {
    size_t i;
    for (i = 0; i < n && s[i] == t[i]; i++)
        if (s[i] == '\0')
            return 0;
    return s[i] - t[i];
}
char* strchr(const char* s, char c) {
    size_t i;
    for (i = 0; s[i] != '\0'; i++)
        if (s[i] == c)
            return &s[i];
    return (char*)0;
}
void* memset(void* s, unsigned char v, size_t n) {
    size_t i;
    for (i = 0; i < n; i++) 
        *(unsigned char*)(s+i) = v;
    return s;
}
void* memcpy(void* s, const void* t, size_t n) {
    size_t words = n / sizeof(int);
    char tail = n % sizeof(int);
    size_t i;
    for (i = 0; i < words; i++) 
        *(int*)(s + i*sizeof(int)) = *(int*)(t + i*sizeof(int));
    char c;
    for (c = 0; c < tail; c++)
        *(char*)(s+i+c) = *(char*)(t+i+c);
    return s;
}
size_t memcmp(const void* s, const void* t, size_t n) {
    size_t i;
    for (i = 0; i < n; i++)
        if (*(char*)(s+i) != *(char*)(t+i))
            return *(char*)(s+i) - *(char*)(t+i);
    return 0;
}