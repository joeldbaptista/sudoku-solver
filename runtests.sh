#!/bin/sh
# Test suite for the sudoku solver. Run it with "make test".
#
# Every case runs a built program (the solver or the generator) and
# checks the exit status together with stdout or stderr. Solutions are checked by
# tests/check.awk, not by comparing against a stored answer, except where
# the puzzle has a single answer and the case names it.
#
# Each run is bounded by timeout(1) when that program is present, so a
# solver that fails to terminate is reported as a failure. Set
# SUDOKU_TEST_TIMEOUT to change the bound, in seconds.

dir=$(dirname "$0")
bin=$dir/main
gen=$dir/generate
tests=$dir/tests
tmp=${TMPDIR:-/tmp}/sudoku-tests.$$
puz=$tmp.a
alt=$tmp.b
limit=${SUDOKU_TEST_TIMEOUT:-10}
timer=$(command -v timeout)
pass=0
fail=0

trap 'rm -f "$tmp" "$puz" "$alt"; exit 2' HUP INT TERM

ok() {
	pass=$((pass + 1))
	printf 'PASS %s\n' "$1"
}

no() {
	fail=$((fail + 1))
	printf 'FAIL %s: %s\n' "$1" "$2"
}

# status STATUS: name an exit status in words.
status() {
	if [ "$1" -eq 124 ] && [ -n "$timer" ]; then
		printf 'timed out after %ss' "$limit"
	else
		printf 'exit %s' "$1"
	fi
}

# run PROG ARGS...: run PROG under the time bound, output in $tmp.
run() {
	if [ -n "$timer" ]; then
		"$timer" "$limit" "$@" > "$tmp" 2>&1
	else
		"$@" > "$tmp" 2>&1
	fi
}

# solves NAME FILE: the solver succeeds and prints a valid solution.
solves() {
	run "$bin" -i "$tests/$2"
	st=$?
	if [ $st -ne 0 ]; then
		no "$1" "$(status $st): $(cat "$tmp")"
		return
	fi
	msg=$(awk -f "$tests/check.awk" "$tests/$2" "$tmp")
	if [ -n "$msg" ]; then
		no "$1" "$msg"
		return
	fi
	ok "$1"
}

# answers NAME FILE EXPECTED: the solution equals the stored answer.
answers() {
	run "$bin" -i "$tests/$2"
	st=$?
	if [ $st -ne 0 ]; then
		no "$1" "$(status $st): $(cat "$tmp")"
		return
	fi
	if ! cmp -s "$tmp" "$tests/$3"; then
		no "$1" "output differs from $3"
		return
	fi
	ok "$1"
}

# digs NAME CELLS SEED: the generator digs CELLS cells, and the solver
# solves the puzzle it writes.
digs() {
	run "$gen" -o "$puz" -d "$2" -s "$3"
	st=$?
	if [ $st -ne 0 ]; then
		no "$1" "$(status $st): $(cat "$tmp")"
		return
	fi
	n=$(tr -cd 0 < "$puz" | wc -c)
	if [ "$n" -ne "$2" ]; then
		no "$1" "dug $n cells, not $2"
		return
	fi
	run "$bin" -i "$puz"
	st=$?
	if [ $st -ne 0 ]; then
		no "$1" "solver: $(status $st): $(cat "$tmp")"
		return
	fi
	msg=$(awk -f "$tests/check.awk" "$puz" "$tmp")
	if [ -n "$msg" ]; then
		no "$1" "$msg"
		return
	fi
	ok "$1"
}

# repeats NAME CELLS SEED: two runs with the same seed write the same
# puzzle.
repeats() {
	if ! "$gen" -o "$puz" -d "$2" -s "$3" ||
	    ! "$gen" -o "$alt" -d "$2" -s "$3"; then
		no "$1" "generator failed"
		return
	fi
	if ! cmp -s "$puz" "$alt"; then
		no "$1" "puzzles differ"
		return
	fi
	ok "$1"
}

# rejects NAME PATTERN PROG ARGS...: PROG exits 1 and complains.
rejects() {
	name=$1
	pat=$2
	shift 2
	run "$@"
	st=$?
	if [ $st -ne 1 ]; then
		no "$name" "expected exit 1, got $(status $st)"
		return
	fi
	if ! grep -q -- "$pat" "$tmp"; then
		no "$name" "message lacks '$pat': $(cat "$tmp")"
		return
	fi
	ok "$name"
}

for p in "$bin" "$gen"; do
	if [ ! -x "$p" ]; then
		echo "runtests.sh: $p is not built" >&2
		exit 2
	fi
done
if [ -z "$timer" ]; then
	echo 'runtests.sh: timeout(1) not found, running unbounded' >&2
fi

answers 'readme example'      simple.dat  simple.out
answers 'solved grid is kept' full.dat    full.out
solves  'compact digits'      compact.dat
solves  'ragged whitespace'   messy.dat
solves  'empty grid'          empty.dat
solves  'hard for backtrack'  hard.dat
solves  'minimal 17 clues'    minimal.dat
solves  'trailing text'       extra.dat

rejects 'no solution'         'no solution'        "$bin" -i "$tests/nosol.dat"
rejects 'repeat in row'       'inconsistent'       "$bin" -i "$tests/duprow.dat"
rejects 'repeat in column'    'inconsistent'       "$bin" -i "$tests/dupcol.dat"
rejects 'repeat in box'       'inconsistent'       "$bin" -i "$tests/dupbox.dat"
rejects 'too few cells'       'expected 81 cells'  "$bin" -i "$tests/short.dat"
rejects 'bad character'       'bad character'      "$bin" -i "$tests/junk.dat"
rejects 'missing file'        'cannot open'        "$bin" -i "$tests/absent.dat"
rejects 'no arguments'        'usage'              "$bin"
rejects 'flag without value'  'usage'              "$bin" -i
rejects 'unknown flag'        'usage'              "$bin" -x foo

digs    'generate, dig 0'     0  1
digs    'generate, dig 30'    30 2
digs    'generate, dig 50'    50 3
digs    'generate, dig 58'    58 4
repeats 'same seed, same puzzle' 40 5

rejects 'gen: no -o'          'usage'        "$gen" -d 10
rejects 'gen: no -d'          'usage'        "$gen" -o "$puz"
rejects 'gen: -d above 64'    'usage'        "$gen" -o "$puz" -d 65
rejects 'gen: negative -d'    'usage'        "$gen" -o "$puz" -d -1
rejects 'gen: -d not a number' 'usage'       "$gen" -o "$puz" -d 3x
rejects 'gen: bad seed'       'usage'        "$gen" -o "$puz" -d 3 -s x
rejects 'gen: unknown flag'   'usage'        "$gen" -x foo
rejects 'gen: cannot dig'     'cannot dig'   "$gen" -o "$puz" -d 64 -s 1
rejects 'gen: bad output'     'cannot open'  "$gen" -o "$tests/absent/x" -d 1

rm -f "$tmp" "$puz" "$alt"
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
