/*
 * Sudoku solver.
 *
 * Reads a 9x9 grid from a file, where 0 marks an empty cell, solves it
 * by backtracking, and writes the solution to stdout.
 */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

static void usage(void);
static int readgrid(const char *path, Grid *g);
static int validmove(const Grid *g, int r, int c, int v);
static int validgrid(const Grid *g);
static int numbits(int m);
static int candidates(const Grid *g, int r, int c);
static int bestempty(const Grid *g, int *r, int *c);
static int solved(Grid *g);
static void printgrid(const Grid *g);

static char *argv0;

static void
usage(void)
{
	fprintf(stderr, "usage: %s -i file\n", argv0);
	exit(1);
}

static int
readgrid(const char *path, Grid *g)
{
	FILE *fp;
	int i;
	int c;
	int ret;

	if (!(fp = fopen(path, "r"))) {
		fprintf(stderr, "%s: cannot open %s\n", argv0, path);
		return -1;
	}
	ret = -1;
	i = 0;
	while (i < N * N && (c = fgetc(fp)) != EOF) {
		if (isspace(c))
			continue;
		if (!isdigit(c)) {
			fprintf(stderr, "%s: %s: bad character '%c'\n",
				argv0, path, c);
			goto cleanup;
		}
		g->v[i / N][i % N] = c - '0';
		++i;
	}
	if (i < N * N) {
		fprintf(stderr, "%s: %s: expected %d cells\n",
			argv0, path, N * N);
		goto cleanup;
	}
	ret = 0;
cleanup:
	fclose(fp);
	return ret;
}

static int
validmove(const Grid *g, int r, int c, int v)
{
	int i, j;
	int br, bc;

	for (i = 0; i < N; ++i)
		if (g->v[r][i] == v || g->v[i][c] == v)
			return 0;
	br = r - r % BOX;
	bc = c - c % BOX;
	for (i = 0; i < BOX; ++i)
		for (j = 0; j < BOX; ++j)
			if (g->v[br + i][bc + j] == v)
				return 0;
	return 1;
}

static int
validgrid(const Grid *g)
{
	Grid tmp;
	int i, j;
	int v;

	tmp = *g;
	for (i = 0; i < N; ++i) {
		for (j = 0; j < N; ++j) {
			if (!(v = tmp.v[i][j]))
				continue;
			tmp.v[i][j] = 0;
			if (!validmove(&tmp, i, j, v))
				return 0;
			tmp.v[i][j] = v;
		}
	}
	return 1;
}

static int
numbits(int m)
{
	int n;

	for (n = 0; m; m &= m - 1)
		++n;
	return n;
}

static int
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

static int
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

static int
solved(Grid *g)
{
	int r, c;
	int v, m;

	if (!bestempty(g, &r, &c))
		return 1;
	m = candidates(g, r, c);
	for (v = 1; v <= N; ++v) {
		if (!(m & (1 << v)))
			continue;
		g->v[r][c] = v;
		if (solved(g))
			return 1;
		g->v[r][c] = 0;
	}
	return 0;
}

static void
printgrid(const Grid *g)
{
	int i, j;

	for (i = 0; i < N; ++i)
		for (j = 0; j < N; ++j)
			printf("%d%c", g->v[i][j],
			    j == N - 1 ? '\n' : ' ');
}

int
main(int argc, char *argv[])
{
	Grid g;
	char *path;
	int i;

	argv0 = argv[0];
	path = NULL;
	for (i = 1; i < argc; ++i) {
		if (strcmp(argv[i], "-i")) {
			usage();
		} else {
			if (++i >= argc)
				usage();
			path = argv[i];
		}
	}
	if (!path)
		usage();
	if (readgrid(path, &g) < 0)
		return 1;
	if (!validgrid(&g)) {
		fprintf(stderr, "%s: %s: inconsistent puzzle\n", argv0, path);
		return 1;
	}
	if (!solved(&g)) {
		fprintf(stderr, "%s: %s: no solution\n", argv0, path);
		return 1;
	}
	printgrid(&g);
	return 0;
}
