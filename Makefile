CC      = cc
CFLAGS  = -std=c99 -pedantic -Wall -Wextra -Os
LDFLAGS =

BIN = main
SRC = main.c
OBJ = $(SRC:.c=.o)

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $(OBJ)

$(OBJ): $(SRC)

.c.o:
	$(CC) $(CFLAGS) -c $<

test: $(BIN)
	./runtests.sh

clean:
	rm -f $(BIN) $(OBJ)

.PHONY: all test clean
