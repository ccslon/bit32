#include <stdio.h>
#include <stdlib.h>
#define LEN 6
typedef struct _Owner_ {
    char* name;
    char age;
} Owner;
Owner owners[LEN] = {
    {"Colin",27},
    {"Mom", 61},
    {"Nick", 24},
    {"Bethany",32},
    {"Evan", 30},
    {"Tanya", 21}
};
struct Coord {
    char x, y;
};
struct Coord coords[LEN] = {
    {1,27},
    {2,61},
    {3,24},
    {4,32},
    {5,30},
    {6,21}
};
int coordcmp(void* a, void* b) {
    return ((struct Coord*)a)->y - ((struct Coord*)b)->y;
}
int ownercmp(void* a, void* b) {
    return ((Owner*)a)->age - ((Owner*)b)->age;
}
int intcmp(void* a, void* b) {
    return *(int*)a - *(int*)b;
}
int ints[LEN] = {6,5,4,3,2,1};

void main() {
    int i;
    // for (i = 0; i < LEN; i++)
    //     printf("%d ", ints[i]);
    // qsort(coords, sizeof(struct Coord), 0, LEN-1, cmpcoord);
    // for (i = 0; i < LEN; i++)
    //     printf("%d %d\n", coords[i].x, coords[i].y);
    // qsort(&ints, sizeof(int), 0, LEN-1, intcmp);
    // for (i = 0; i < LEN; i++)
    //     printf("%d ", ints[i]);
    for (i = 0; i < LEN; i++)
        printf("%s %d\n", owners[i].name, owners[i].age);
    putchar('\n');
    printf("%d\n", sizeof(Owner));
    qsort(owners, sizeof(Owner), 0, LEN-1, ownercmp);
    for (i = 0; i < LEN; i++)
        printf("%s %d\n", owners[i].name, owners[i].age);
    putchar('\n');
    //bsearch
    // for (i = 0; i < N; i++) {
    //     printf("%d\n", bsearch(i, sarr, 6, &intcmp));
    // }
}
