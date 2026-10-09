/*
 * Grid helpers shared by the solver and the generator.
 */
#include <stdio.h>

#include "sudoku.h"

/* numbits returns the number of bits set in m. */
int
numbits(int m)
{
	int n;

	for (n = 0; m; m &= m - 1)
		++n;
	return n;
}

/* candidates returns the mask of digits that fit at row r, column c. */
int
candidates(const Grid *g, int r, int c)
{
	int i, j;
	int br, bc;
	int m;

	m = 0;
	for (i = 0; i < N; ++i)
		m |= (1 << g->v[r][i]) | (1 << g->v[i][c]);
	br = r - r % BOX;
	bc = c - c % BOX;
	for (i = 0; i < BOX; ++i)
		for (j = 0; j < BOX; ++j)
			m |= 1 << g->v[br + i][bc + j];
	return ~m & MASKALL;
}

/*
 * bestempty stores in *r and *c the empty cell with the fewest
 * candidates, and returns 1. It returns 0 when no cell is empty.
 */
int
bestempty(const Grid *g, int *r, int *c)
{
	int i, j;
	int n, min;

	min = N + 1;
	for (i = 0; i < N; ++i) {
		for (j = 0; j < N; ++j) {
			if (g->v[i][j])
				continue;
			n = numbits(candidates(g, i, j));
			if (n >= min)
				continue;
			min = n;
			*r = i;
			*c = j;
			if (!n)
				return 1;
		}
	}
	return min <= N;
}

/* writegrid writes g to fp, one row per line. */
void
writegrid(FILE *fp, const Grid *g)
{
	int i, j;

	for (i = 0; i < N; ++i)
		for (j = 0; j < N; ++j)
			fprintf(fp, "%d%c", g->v[i][j],
			    j == N - 1 ? '\n' : ' ');
}
