/*
 * Grid type and helpers shared by the solver and the generator.
 * Include <stdio.h> before this file.
 */

/* bits 1 to 9 set: the candidate mask of a cell with no constraint */
#define MASKALL 0x3fe

enum {
	N   = 9,
	BOX = 3
};

typedef struct grid Grid;
struct grid {
	int v[N][N];
};

int numbits(int m);
int candidates(const Grid *g, int r, int c);
int bestempty(const Grid *g, int *r, int *c);
void writegrid(FILE *fp, const Grid *g);
