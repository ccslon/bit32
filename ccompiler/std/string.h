#define STRING_H
typedef unsigned size_t;
size_t strlen(const char*);
size_t strnlen(const char*, size_t);
char* strcpy(char*, const char*);
char* strncpy(char*, const char*, size_t);
char* strdup(const char*);
char* strndup(const char*, size_t);
char* strcat(char*, const char*);
char* strncat(char*, const char*, size_t);
char* strrev(char*);
char* strnrev(char*, size_t);
int strcmp(const char*, const char*);
int strncmp(const char*, const char*, size_t);
char* strchr(const char*, char);
void* memset(void*, unsigned char, size_t);
void* memcpy(void*, const void*, size_t);
void* memmove(void*, const void*, size_t);
size_t memcmp(const void*, const void*, size_t);