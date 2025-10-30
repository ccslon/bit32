//Test 1 ----------------------------------------------------
#define A 1

#if A
int x = 1;
#else
int x = 0;
#endif

//Test 2 ----------------------------------------------------
#define B 2

#if B == 1
int y = 1;
#elif B == 2
int y = 2;
#else
int y = 0;
#endif

//Test 3 ----------------------------------------------------
#define C 1
#define D 0

#if C
#if D
int z = 1;
#else
int z = 2;
#endif
#else
int z = 0;
#endif

//Test 4 ----------------------------------------------------
#define E 0
#define F 1

#if E
int a = 1;
#elif F
#if F == 1
int a = 2;
#else
int a = 3;
#endif
#else
int a = 0;
#endif

//Test 5 ----------------------------------------------------
#define G 3

#if G == 1
int b = 1;
#elif G == 2
int b = 2;
#elif G == 3
int b = 3;
#else
int b = 0;
#endif

//Test 6 ----------------------------------------------------
#define H 1
#define I 0
#define J 1

#if H
#if I
int c = 1;
#elif J
int c = 2;
#else
int c = 3;
#endif
#else
int c = 0;
#endif

//Test 7 ----------------------------------------------------
#if UNDEFINED_MACRO
int d = 1;
#else
int d = 0;
#endif

//Test 8 ----------------------------------------------------
#define K 1
#define L 0

#if K && L
int e = 1;
#elif K || L
int e = 2;
#else
int e = 3;
#endif

//Test 9 ----------------------------------------------------
#define M 5
#define N M + 1

#if N == 6
int f = 1;
#else
int f = 0;
#endif

//Test 10 ---------------------------------------------------
#define O 2

#if (O * 3 + 1) == 7
int g = 1;
#else
int g = 0;
#endif

//Test 11 ---------------------------------------------------
#define P 1
#define Q 0
#define R 1

#if P
#if Q || R
int h = 1;
#else
int h = 2;
#endif
#else
int h = 3;
#endif

//Test 12 ---------------------------------------------------
#define S 0
#define T 1
#define U 0

#if S
int i = 1;
#elif T
#if U
int i = 2;
#else
int i = 3;
#endif
#else
int i = 4;
#endif

//Test 13 ---------------------------------------------------
#if S == U
int i = 1;
#if T
int j = 5678;
#elif U
int i = 2;
#else
int i = 3;
#endif
#else
int i = 4;
#endif