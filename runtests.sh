#!/bin/sh
# Test suite for the sudoku solver. Run it with "make test".
#
# Every case runs the built binary on a file under tests/ and checks the
# exit status together with stdout or stderr. Solutions are checked by
# tests/check.awk, not by comparing against a stored answer, except where
# the puzzle has a single answer and the case names it.
#
# Each run is bounded by timeout(1) when that program is present, so a
# solver that fails to terminate is reported as a failure. Set
# SUDOKU_TEST_TIMEOUT to change the bound, in seconds.

dir=$(dirname "$0")
bin=$dir/main
tests=$dir/tests
tmp=${TMPDIR:-/tmp}/sudoku-tests.$$
limit=${SUDOKU_TEST_TIMEOUT:-10}
timer=$(command -v timeout)
pass=0
fail=0

trap 'rm -f "$tmp"; exit 2' HUP INT TERM

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

# run ARGS...: run the solver under the time bound, output in $tmp.
run() {
	if [ -n "$timer" ]; then
		"$timer" "$limit" "$bin" "$@" > "$tmp" 2>&1
	else
		"$bin" "$@" > "$tmp" 2>&1
	fi
}

# solves NAME FILE: the solver succeeds and prints a valid solution.
solves() {
	run -i "$tests/$2"
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
	run -i "$tests/$2"
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

# rejects NAME PATTERN ARGS...: the solver exits 1 and complains.
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

if [ ! -x "$bin" ]; then
	echo 'runtests.sh: main is not built' >&2
	exit 2
fi
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

rejects 'no solution'         'no solution'        -i "$tests/nosol.dat"
rejects 'repeat in row'       'inconsistent'       -i "$tests/duprow.dat"
rejects 'repeat in column'    'inconsistent'       -i "$tests/dupcol.dat"
rejects 'repeat in box'       'inconsistent'       -i "$tests/dupbox.dat"
rejects 'too few cells'       'expected 81 cells'  -i "$tests/short.dat"
rejects 'bad character'       'bad character'      -i "$tests/junk.dat"
rejects 'missing file'        'cannot open'        -i "$tests/absent.dat"
rejects 'no arguments'        'usage'
rejects 'flag without value'  'usage'              -i
rejects 'unknown flag'        'usage'              -x foo

rm -f "$tmp"
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
