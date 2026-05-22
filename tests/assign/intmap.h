#ifndef INTMAP_H
#define INTMAP_H
#include <stdbool.h>
#define MAP_SIZE 16
typedef struct Pair {
    char* key;
    int value;
    struct Pair* next;
} Pair;
typedef struct IntMap {
    Pair** data;
    int size;
    int capacity;
} IntMap;
IntMap* _allocIntMap(unsigned);
#define allocIntMap() _allocIntMap(MAP_SIZE)
unsigned hash(char*);
unsigned IntMap_hash(IntMap*, char*);
Pair* IntMap_get(IntMap*, char*);
bool IntMap_in(IntMap*, char*);
void _IntMap_rehash(IntMap*, Pair*);
IntMap* _IntMap_resize(IntMap*);
void IntMap_set(IntMap*, char*, int);
void HashMap_del(IntMap*, char*);
void freePairs(Pair*);
void freeIntMap(IntMap*);
#endif
