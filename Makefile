CC      = cc
CFLAGS  = -std=c99 -pedantic -Wall -Wextra -Os
LDFLAGS =

BIN = main generate
SRC = main.c generate.c sudoku.c
OBJ = $(SRC:.c=.o)

all: $(BIN)

main: main.o sudoku.o
	$(CC) $(LDFLAGS) -o $@ main.o sudoku.o

generate: generate.o sudoku.o
	$(CC) $(LDFLAGS) -o $@ generate.o sudoku.o

$(OBJ): sudoku.h

.c.o:
	$(CC) $(CFLAGS) -c $<

test: $(BIN)
	./runtests.sh

clean:
	rm -f $(BIN) $(OBJ)

.PHONY: all test clean
