#include <string.h>
#include <stdlib.h>
#define MAP_SIZE 16
typedef struct Pair {
    char* key;
    void* value;
    struct Pair* next;
} Pair;
unsigned hash(char* key) {
    unsigned hash;
    for (hash = 0; *key != '\0'; key++) {
        hash = *key + 31 * hash;
    }
    return hash % MAP_SIZE;
}
void initMap(Pair* map[]) {
    int i;
    for (i = 0; i < MAP_SIZE; i++) {
        map[i] = NULL;
    }
}
Pair* get(Pair* map[], char* key) {
    Pair* pair;
    for (pair = map[hash(key)]; pair != NULL; pair = pair->next) {
        if (strcmp(key, pair->key) == 0) {
            return pair;
        }
    }
    return NULL;
}
int in(Pair* map[], char* key) {
    return get(map, key) != NULL;
}
void set(Pair* map[], char* key, void* value) {
    Pair* pair;
    if (!in(map, key)) {
        pair = malloc(sizeof(Pair));
        pair->key = key;
        unsigned h = hash(key);
        if (map[h] == NULL) {
            pair->next = NULL;
            map[h] = pair;
        } else {
            pair->next = map[h]->next;
            map[h]->next = pair;
        }
    }
    pair = get(map, key);
    free(pair->value);
    pair->value = value;
}
#define SET(type, map, key, value) type* ptr = malloc(sizeof(type)); *ptr = value; set(map, key, ptr);
void setint(Pair* map[], char* key, int value) {
    int* ptr = malloc(sizeof(int));
    *ptr = value;
    set(map, key, ptr);
}
void del(Pair* map[], char* key) {
    Pair* pair;
    if (in(map, key)) {
        unsigned h = hash(key);
        if (strcmp(key, map[h]->key) == 0) {
            pair = map[h];
            map[h] = pair->next;
        } else {
            Pair* prev;
            for (prev = map[h], pair = prev->next; pair != NULL; prev = pair, pair = prev->next) {
                if (strcmp(key, pair->key) == 0) {
                    prev->next = pair->next;
                }
            }
        }
        free(pair->value);
        free(pair);
    }
}
void freePairs(Pair* pair) {
    while (pair != NULL) {
        Pair* temp = pair;
        pair = pair->next;
        free(temp->value);
        free(temp);
    }
}
void freeMap(Pair* map[]) {
    unsigned i;
    for (i = 0; i < MAP_SIZE; i++) {
        if (map[i] != NULL) {
            freePairs(map[i]);
        }
    }
}