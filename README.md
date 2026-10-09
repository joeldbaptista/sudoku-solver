# Sudoku solver

This is an implementation of a sudoku solver. An explanation of what sudoku is
can be found [here](https://en.wikipedia.org/wiki/Sudoku). 

The current solution works only with numbers from 1 to 9.

## How it works.

Build it with `make`. Then, provide a file with a 9x9 matrix where 0
represents no number, and run this:

```shell
$ ./main -i puzzle.dat
```

The solution is printed in `stdout`.

## Generating puzzles

`generate` writes a new puzzle with a unique solution:

```shell
$ ./generate -o new.dat -d 50 [-s seed]
```

It fills a grid at random, then digs cells in random order ("generate and
dig"). A dug cell stays empty only while the puzzle keeps a unique
solution. `-d` is the number of cells to dig, from 0 to 64, since a unique
puzzle keeps at least 17 givens. Random digging rarely gets past about 59,
so the program gives up after 100 grids and exits 1. `-s` fixes the seed of
`rand(3)`, so the same seed gives the same puzzle.

The code shared by both programs is in `sudoku.c` and `sudoku.h`.

## Tests

Run the suite with:

```shell
$ make test
```

Each case runs `./main` or `./generate` and checks the exit status
together with the output. A solution is checked by `tests/check.awk`, which
verifies the rows, the columns, the boxes, and the givens, rather than
comparing against a stored answer. Two cases are the exception: they use a
puzzle whose answer is unique, so they compare against that stored answer.
Each run is bounded by
`timeout(1)`, so a solver that does not terminate is reported as a failure.
Set `SUDOKU_TEST_TIMEOUT` to change that bound, in seconds.

## About code style

Read `STYLE.md`.
