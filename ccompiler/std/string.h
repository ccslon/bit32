#define STRING_H
typedef unsigned size_t;
size_t strlen(const char*);
char* strcpy(char*, const char*);
char* strncpy(char*, const char*, size_t);
char* strdup(char*);
char* strcat(char*, const char*);
char* strrev(char*);
int strcmp(const char*, const char*);
int strncmp(const char*, const char*, size_t);
char* strchr(const char*, char);
void* memset(void*, unsigned char, size_t);
void* memcpy(void*, const void*, size_t);
size_t memcmp(const void*, const void*, size_t);