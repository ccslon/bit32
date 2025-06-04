#include <string.h>
#include <stdlib.h>
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
IntMap* _allocIntMap(unsigned size) {
    IntMap* map = malloc(sizeof(IntMap));
    map->data = calloc(size, sizeof(Pair*));
    map->size = 0;
    map->capacity = size;
    return map;
}
#define allocIntMap() _allocIntMap(MAP_SIZE)
unsigned hash(char* key) {
    unsigned hash;
    for (hash = 0; *key != '\0'; key++) {
        hash = *key + 31 * hash;
    }
    return hash;
}
unsigned IntMap_hash(IntMap* map, char* key) {
    return hash(key) % map->capacity;
}
Pair* IntMap_get(IntMap* map, char* key) {
    if (map != NULL) {
        Pair* pair;
        for (pair = map->data[IntMap_hash(map, key)]; pair != NULL; pair = pair->next) {
            if (strcmp(key, pair->key) == 0) {
                return pair;
            }
        }
    }    
    return NULL;
}
bool IntMap_in(IntMap* map, char* key) {
    return IntMap_get(map, key) != NULL;
}
void _IntMap_rehash(IntMap* map, Pair* pair) {
    void IntMap_set(IntMap*, char*, int);
    while (pair != NULL) {
        IntMap_set(map, pair->key, pair->value);
        pair = pair->next;
    }
}
IntMap* _IntMap_resize(IntMap* old) {
    IntMap* map = _allocIntMap(2*old->capacity);
    int i;
    for (i = 0; i < old->capacity; i++) {
        _IntMap_rehash(map, old->data[i]);
    }
    free(old->data);
    free(old);
    return map;
}
void IntMap_set(IntMap* map, char* key, int value) {
    if (map != NULL) {
        if (map->size == map->capacity) {
            map = _IntMap_resize(map);
        }
        Pair* pair;
        if (!IntMap_in(map, key)) {
            pair = malloc(sizeof(Pair));
            pair->key = key;
            unsigned h = IntMap_hash(map, key);
            if (map->data[h] == NULL) {
                pair->next = NULL;
                map->data[h] = pair;
            } else {
                pair->next = map->data[h]->next;
                map->data[h]->next = pair;
            }
            map->size++;
        }
        pair = IntMap_get(map, key);
        pair->value = value;
    }
}
void freePairs(Pair* pair) {
    while (pair != NULL) {
        Pair* temp = pair;
        pair = pair->next;
        free(temp);
    }
}
void freeIntMap(IntMap* map) {
    if (map != NULL) {
        int i;
        for (i = 0; i < map->capacity; i++) {
            freePairs(map->data[i]);
        }
    }
    free(map->data);
    free(map);
}

IntMap* env;
void test() {
    env = allocIntMap();
    IntMap_set(env, "a", 3);
    IntMap_set(env, "b", 4);
    IntMap_set(env, "c", 7);
}

