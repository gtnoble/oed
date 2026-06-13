#!/bin/sh
# t10_errors.sh: test error handling, ? token output and exit codes
_current_file="t10_errors"
. "$(dirname "$0")/../harness.sh"

# Bad absolute address prints ? and exits 1
run_test "bad absolute address prints question mark" \
    "$(printf '999p\nQ\n')" \
    "?"

run_test_exit "bad absolute address exits with code 1" \
    "$(printf '999p\nQ\n')" \
    "1"

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
    "$(printf 'a\nfoo\n.\n@\nQ\n')" \
    "?"

# Multiple errors: each prints ?; -l (loose) continues
run_test "loose mode continues after error" \
    "$(printf '999p\n,p\nQ\n')" \
    "$(printf '?\n?')" "-l"

# Exit 0 on clean run
run_test_exit "clean run exits 0" \
    "$(printf 'a\nfoo\n.\n,p\nQ\n')" \
    "0"

# Exit 1 on ERR-level error
run_test_exit "error run exits 1" \
    "$(printf '999p\nQ\n')" \
    "1"


# EMOD: unsaved-buffer quit exits 2 (distinct from ERR which exits 1)
# Run without -s so 'q' triggers EMOD path.
printf 'a\nfoo\n.\nq\n' | "$HED" >/dev/null 2>&1
_emod_exit=$?
if [ "$_emod_exit" = "2" ]; then
    _passes=$((_passes + 1))
    printf 'PASS  %s: unsaved buffer on q exits 2\n' "$_current_file"
else
    _failures=$((_failures + 1))
    printf 'FAIL  %s: unsaved buffer on q exits 2 (expected 2, got %s)\n' \
        "$_current_file" "$_emod_exit"
fi
# No-match error message includes pattern in verbose output (s command)
_got=$(printf 'a\nfoo\n.\ns/bar/baz/\nQ\n' | "$HED" -s -v 2>&1)
if [ "$_got" = "$(printf 'script, line 4: no match for pattern "bar"\n?\n')" ]; then
    _passes=$((_passes + 1))
    printf 'PASS  %s: %s\n' "$_current_file" "s no match includes pattern in verbose output"
else
    _failures=$((_failures + 1))
    printf 'FAIL  %s: s no match includes pattern in verbose output\n' "$_current_file"
    printf '  expected: [script, line 4: no match for pattern "bar"\\n?]\n'
    printf '  got:      [%s]\n' "$_got"
fi

# No-match error message includes pattern via search address
_got=$(printf 'a\nfoo\n.\n/nomatch/p\nQ\n' | "$HED" -s -v 2>&1)
if [ "$_got" = "$(printf 'script, line 4: no match for pattern "nomatch"\n?\n')" ]; then
    _passes=$((_passes + 1))
    printf 'PASS  %s: %s\n' "$_current_file" "search addr no match includes pattern in verbose output"
else
    _failures=$((_failures + 1))
    printf 'FAIL  %s: search addr no match includes pattern in verbose output\n' "$_current_file"
    printf '  expected: [script, line 4: no match for pattern "nomatch"\\n?]\n'
    printf '  got:      [%s]\n' "$_got"
fi

# No-match error message includes hash value for hash address
_got=$(printf 'a\nfoo\nbar\n.\n@deadbeef=\nQ\n' | "$HED" -s -v 2>&1)
if [ "$_got" = "$(printf 'script, line 5: no match for hash address @deadbeef\n?\n')" ]; then
    _passes=$((_passes + 1))
    printf 'PASS  %s: %s\n' "$_current_file" "hash addr no match includes hash value in verbose output"
else
    _failures=$((_failures + 1))
    printf 'FAIL  %s: hash addr no match includes hash value in verbose output\n' "$_current_file"
    printf '  expected: [script, line 5: no match for hash address @deadbeef\\n?]\n'
    printf '  got:      [%s]\n' "$_got"
fi

# PCRE2 s command no match includes pattern
_got=$(printf 'a\nfoo\n.\ns/bar/baz/=1\nQ\n' | "$HED" -s -v -P 2>&1)
if [ "$_got" = "$(printf 'script, line 4: no match for pattern "bar"\n?\n')" ]; then
    _passes=$((_passes + 1))
    printf 'PASS  %s: %s\n' "$_current_file" "s -P no match includes pattern in verbose output"
else
    _failures=$((_failures + 1))
    printf 'FAIL  %s: s -P no match includes pattern in verbose output\n' "$_current_file"
    printf '  expected: [script, line 4: no match for pattern "bar"\\n?]\n'
    printf '  got:      [%s]\n' "$_got"
fi

# ERE s command no match includes pattern
_got=$(printf 'a\nfoo\n.\ns/bar/baz/\nQ\n' | "$HED" -s -v -E 2>&1)
if [ "$_got" = "$(printf 'script, line 4: no match for pattern "bar"\n?\n')" ]; then
    _passes=$((_passes + 1))
    printf 'PASS  %s: %s\n' "$_current_file" "s -E no match includes pattern in verbose output"
else
    _failures=$((_failures + 1))
    printf 'FAIL  %s: s -E no match includes pattern in verbose output\n' "$_current_file"
    printf '  expected: [script, line 4: no match for pattern "bar"\\n?]\n'
    printf '  got:      [%s]\n' "$_got"

fi
report
