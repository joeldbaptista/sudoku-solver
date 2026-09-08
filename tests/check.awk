# Verify a sudoku solution.
#
# Usage: awk -f check.awk puzzle.dat solution.txt
#
# Reads the digits of both files, ignoring layout, and like the solver
# it stops at the 81st digit of the puzzle. Exits 0 when the
# solution holds 81 digits, repeats every non-zero cell of the puzzle,
# and holds each of 1 to 9 once per row, per column, and per box.
# Otherwise it prints the reason and exits 1.

{
	for (i = 1; i <= length($0); i++) {
		c = substr($0, i, 1)
		if (c !~ /[0-9]/)
			continue
		if (NR == FNR) {
			if (np < 81)
				p[np++] = c + 0
		} else {
			s[ns++] = c + 0
		}
	}
}

function group(name, i0, step1, n1, step2, n2,   a, b, k, seen, v) {
	for (k = 1; k <= 9; k++)
		seen[k] = 0
	for (a = 0; a < n1; a++) {
		for (b = 0; b < n2; b++) {
			v = s[i0 + a * step1 + b * step2]
			if (v < 1 || v > 9) {
				printf "%s: value %d\n", name, v
				return 1
			}
			if (seen[v]++) {
				printf "%s: repeated %d\n", name, v
				return 1
			}
		}
	}
	return 0
}

END {
	if (np != 81) {
		printf "puzzle holds %d cells\n", np
		exit 1
	}
	if (ns != 81) {
		printf "solution holds %d cells\n", ns
		exit 1
	}
	for (i = 0; i < 81; i++) {
		if (p[i] && p[i] != s[i]) {
			printf "cell %d: given %d became %d\n", i, p[i], s[i]
			exit 1
		}
	}
	for (i = 0; i < 9; i++) {
		if (group("row " i, i * 9, 1, 9, 0, 1))
			exit 1
		if (group("column " i, i, 9, 9, 0, 1))
			exit 1
	}
	for (i = 0; i < 9; i++) {
		j = int(i / 3) * 27 + (i % 3) * 3
		if (group("box " i, j, 9, 3, 1, 3))
			exit 1
	}
	exit 0
}
