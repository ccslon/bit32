#include <string.h>
typedef unsigned size_t;
#define NULL (void*)0
typedef struct Header {
    struct Header* next;
    size_t size;
} Header;
extern char stdheap[];
Header* head = NULL;
Header* tail = NULL;
void* malloc(size_t bytes) {
    if (tail == NULL) {
        tail = (Header*)stdheap;
    }
    Header *ptr, *prev = NULL;
    for (ptr = head; ptr != NULL; prev = ptr, ptr = ptr->next) {
        if (ptr->size >= bytes) {
            if (sizeof(Header) + bytes <= ptr->size / 2) {
                Header* slice = ptr + 1 + bytes;
                slice->size = ptr->size - bytes - sizeof(Header);
                slice->next = ptr->next;
                ptr->size = bytes;
                if (prev == NULL) {
                    head = slice;
                } else {
                    prev->next = slice;
                }
            } else {
                if (prev == NULL) {
                    head = ptr->next;
                } else {
                    prev->next = ptr->next;
                }
            }
            ptr->next = NULL;
            return ptr;
        }
    }
    tail->size = bytes;
    tail->next = NULL;
    ptr = tail + 1;
    tail = tail + 1 + bytes;
    return ptr;
}
void free(void* ptr) {
    if (ptr != NULL) {
        Header* header = (Header*)ptr - 1;
        header->next = head;
        head = header;
        Header* maybe = head + 1 + head->size;
        if (head->next == maybe) {
            head->next = maybe->next;
            head->size += sizeof(Header) + maybe->size;
        }
    }    
}
void* realloc(void* ptr, size_t bytes) {
    Header* header = (Header*)ptr - 1;
    void* new = malloc(bytes);
    memcpy(new, ptr, header->size);
    free(ptr);
    return new;
}
void* calloc(size_t n, size_t size) {
    size_t bytes = n*size;
    void* ptr = malloc(bytes);
    memset(ptr, 0, bytes);
    return ptr;
}