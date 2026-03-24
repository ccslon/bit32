#include <string.h>
#include <stdlib.h>
#include "intmap.h"
IntMap* _allocIntMap(unsigned size) {
    IntMap* map = malloc(sizeof(IntMap));
    map->data = calloc(size, sizeof(Pair*));
    map->size = 0;
    map->capacity = size;
    return map;
}
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
            pair->key = strdup(key);
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
void IntMap_del(IntMap* map, char* key) {
    if (map != NULL) {   
        Pair* pair;
        if (IntMap_in(map, key)) {
            unsigned h = IntMap_hash(map, key);
            if (strcmp(key, map->data[h]->key) == 0) {
                pair = map->data[h];
                map->data[h] = pair->next;
            } else {
                Pair* prev;
                for (prev = map->data[h], pair = prev->next; pair != NULL; prev = pair, pair = prev->next) {
                    if (strcmp(key, pair->key) == 0) {
                        prev->next = pair->next;
                    }
                }
            }
            free(pair->key);
            free(pair);
            map->size--;
        }
    }
}
void freePairs(Pair* pair) {
    while (pair != NULL) {
        Pair* temp = pair;
        pair = pair->next;
        free(temp->key);
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
