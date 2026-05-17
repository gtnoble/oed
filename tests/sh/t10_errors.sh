#!/bin/sh
# t10_errors.sh: test error handling, ? token output and exit codes
_current_file="t10_errors"
. "$(dirname "$0")/../harness.sh"

# Bad absolute address prints ? and exits 2
run_test "bad absolute address prints question mark" \
    "$(printf '999p\nQ\n')" \
    "?"

run_test_exit "bad absolute address exits with code 2" \
    "$(printf '999p\nQ\n')" \
    "2"

# Address out of range: 0p on empty buffer
run_test "address out of range on empty buffer" \
    "$(printf '1p\nQ\n')" \
    "?"

# Address beyond last line
run_test "address beyond addr_last" \
    "$(printf 'a\nfoo\n.\n5p\nQ\n')" \
    "?"

# Bad regex prints ?
run_test "unclosed bracket in regex prints question mark" \
    "$(printf 'a\nfoo\n.\n/[/p\nQ\n')" \
    "?"

# Substitution on non-matching line prints ?
run_test "substitution no match prints question mark" \
    "$(printf 'a\nfoo\n.\ns/bar/baz/\nQ\n')" \
    "?"

# Unknown command prints ?
run_test "unknown command prints question mark" \
    "$(printf 'a\nfoo\n.\nZ\nQ\n')" \
    "?"

# Multiple errors: each prints ?; -l (loose) continues
run_test "loose mode continues after error" \
    "$(printf '999p\n,p\nQ\n')" \
    "$(printf '?\n?')" "-l"

# Exit 0 on clean run
run_test_exit "clean run exits 0" \
    "$(printf 'a\nfoo\n.\n,p\nQ\n')" \
    "0"

# Exit 2 on any error
run_test_exit "error run exits 2" \
    "$(printf '999p\nQ\n')" \
    "2"

report
