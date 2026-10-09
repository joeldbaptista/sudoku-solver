/*
 * Sudoku generator.
 *
 * Fills a grid at random, then digs its cells in random order. A dug
 * cell stays empty only while the puzzle keeps a unique solution. The
 * puzzle is written to a file in the format that the solver reads.
 */
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "sudoku.h"

/* a unique puzzle keeps at least 17 givens */
#define MAXDIG (N * N - 17)
/* number of full grids to dig before giving up */
#define MAXTRY 100

static void usage(void);
static int number(const char *s, long min, long max, long *n);
static void shuffle(int *a, int n);
static int filled(Grid *g);
static int numsol(Grid *g, int max);
static int dug(Grid *g, int d);

static char *argv0;

static void
usage(void)
{
	fprintf(stderr, "usage: %s -o file -d cells [-s seed]\n", argv0);
	exit(1);
}

/*
 * number stores in *n the decimal integer in s, and returns 0.
 * It returns -1 when s is not an integer in [min, max].
 */
static int
number(const char *s, long min, long max, long *n)
{
	char *end;

	if (!*s)
		return -1;
	*n = strtol(s, &end, 10);
	if (*end || *n < min || *n > max)
		return -1;
	return 0;
}

/* shuffle puts the n elements of a in random order (Fisher-Yates). */
static void
shuffle(int *a, int n)
{
	int i, j;
	int tmp;

	for (i = n - 1; i > 0; --i) {
		j = rand() % (i + 1);
		tmp = a[i];
		a[i] = a[j];
		a[j] = tmp;
	}
}

/*
 * filled fills the empty cells of g by backtracking, trying the digits
 * of each cell in random order. It returns 1 when g ends full.
 */
static int
filled(Grid *g)
{
	int r, c;
	int i, m;
	int v[N];

	if (!bestempty(g, &r, &c))
		return 1;
	m = candidates(g, r, c);
	for (i = 0; i < N; ++i)
		v[i] = i + 1;
	shuffle(v, N);
	for (i = 0; i < N; ++i) {
		if (!(m & (1 << v[i])))
			continue;
		g->v[r][c] = v[i];
		if (filled(g))
			return 1;
		g->v[r][c] = 0;
	}
	return 0;
}

/*
 * numsol returns the number of solutions of g, but stops counting at
 * max. It leaves g as it found it.
 */
static int
numsol(Grid *g, int max)
{
	int r, c;
	int v, m;
	int n;

	if (!bestempty(g, &r, &c))
		return 1;
	m = candidates(g, r, c);
	n = 0;
	for (v = 1; v <= N && n < max; ++v) {
		if (!(m & (1 << v)))
			continue;
		g->v[r][c] = v;
		n += numsol(g, max - n);
		g->v[r][c] = 0;
	}
	return n;
}

/*
 * dug digs d cells of the full grid g, visiting the cells in random
 * order and keeping a dig only when the solution stays unique. It
 * returns 1 when it dug d cells.
 */
static int
dug(Grid *g, int d)
{
	int cell[N * N];
	int i, k;
	int r, c, v;

	for (i = 0; i < N * N; ++i)
		cell[i] = i;
	shuffle(cell, N * N);
	k = 0;
	for (i = 0; i < N * N && k < d; ++i) {
		r = cell[i] / N;
		c = cell[i] % N;
		v = g->v[r][c];
		g->v[r][c] = 0;
		if (numsol(g, 2) == 1)
			++k;
		else
			g->v[r][c] = v;
	}
	return k == d;
}

int
main(int argc, char *argv[])
{
	Grid g;
	FILE *fp;
	char *path;
	long d;
	long seed;
	int i;

	argv0 = argv[0];
	path = NULL;
	d = -1;
	seed = -1;
	for (i = 1; i < argc; ++i) {
		if (i + 1 >= argc)
			usage();
		if (!strcmp(argv[i], "-o")) {
			path = argv[++i];
		} else if (!strcmp(argv[i], "-d")) {
			if (number(argv[++i], 0, MAXDIG, &d) < 0)
				usage();
		} else if (!strcmp(argv[i], "-s")) {
			if (number(argv[++i], 0, INT_MAX, &seed) < 0)
				usage();
		} else {
			usage();
		}
	}
	if (!path || d < 0)
		usage();
	if (seed < 0)
		srand((unsigned)time(NULL) ^ (unsigned)getpid());
	else
		srand((unsigned)seed);

	for (i = 0; i < MAXTRY; ++i) {
		memset(&g, 0, sizeof(g));
		filled(&g);
		if (dug(&g, d))
			break;
	}
	if (i == MAXTRY) {
		fprintf(stderr, "%s: cannot dig %ld cells in %d grids\n",
			argv0, d, MAXTRY);
		return 1;
	}

	if (!(fp = fopen(path, "w"))) {
		fprintf(stderr, "%s: cannot open %s\n", argv0, path);
		return 1;
	}
	writegrid(fp, &g);
	if (fclose(fp) == EOF) {
		fprintf(stderr, "%s: cannot write %s\n", argv0, path);
		return 1;
	}
	return 0;
}
