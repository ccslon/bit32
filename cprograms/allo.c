#include <stdio.h>
typedef struct Header {
    struct Header* next;
    size_t size;
} Header;
#define HEAP_SIZE 20
char* stdheap[HEAP_SIZE];
Header* head = NULL;
Header* tail = NULL;
void* malloc(size_t bytes) {
    if (tail == NULL) {
        tail = (Header*)stdheap;
    }
    Header *ptr, *prev = NULL;
    for (ptr = head; ptr != NULL; prev = ptr, ptr = ptr->next) {
        if (ptr->size >= bytes) {
            if (ptr->size - bytes > sizeof(Header)) {
                if (prev == NULL) {
                    head = ptr + 1 + bytes;
                    head->size = ptr->size - bytes - sizeof(Header);
                    head->next = ptr->next;
                    ptr->next = NULL;
                } else {
                    prev->next = ptr->next;
                }
                return ptr;
            } else {
                if (prev == NULL) {
                    head = ptr->next;
                } else {
                    prev->next = ptr->next;
                }
            }
            return ptr;
        }
    }
    tail->size = bytes;
    ptr = tail + 1;
    tail = tail + 1 + bytes;
    return ptr;

}
void free(void* ptr) {
    Header* header = (Header*)ptr - 1;
    header->next = head;
    head = header;
    Header* maybe = head + 1 + head->size;
    if (head->next == maybe) {
        head->next = maybe->next;
        head->size += sizeof(Header) + maybe->size;
    }
}

void print() {
    int i;
    for (i = 0; i < HEAP_SIZE; i++) {
        printf("%hhu ", stdheap[i]);
        if (i + 1 % 4) {
            putchar('\n');
        }
    }
}

int main() {
    print();
    void* ptr = malloc(16);
    print();
    free(ptr);
    print();
}