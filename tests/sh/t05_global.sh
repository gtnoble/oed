#!/bin/sh
# t05_global.sh: test g, v commands
_current_file="t05_global"
. "$(dirname "$0")/../harness.sh"

# g deletes matching lines
run_test "g command deletes matching lines" \
    "$(printf 'a\nfoo\nbar\nfoo2\n.\ng/foo/d\n,p\nQ\n')" \
    "bar"

# v deletes non-matching lines
run_test "v command deletes non-matching lines" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\nv/bar/d\n,p\nQ\n')" \
    "bar"

# g with print
run_test "g command prints matching lines" \
    "$(printf 'a\nfoo\nbar\nfoo2\n.\ng/foo/p\nQ\n')" \
    "$(printf 'foo\nfoo2')"

# g with substitution
run_test "g command applies substitution to matching lines" \
    "$(printf 'a\nfoo\nbar\nfoo2\n.\ng/foo/s/foo/baz/\n,p\nQ\n')" \
    "$(printf 'baz\nbar\nbaz2')"

# v with substitution
run_test "v command applies substitution to non-matching lines" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\nv/foo/s/$/!/\n,p\nQ\n')" \
    "$(printf 'foo\nbar!\nbaz!')"

# g over a range
run_test "g command restricted to range" \
    "$(printf 'a\nfoo\nbar\nfoo\n.\n1,2g/foo/d\n,p\nQ\n')" \
    "$(printf 'bar\nfoo')"

# g with multiple commands separated by newline
run_test "g command with multiple sub-commands" \
    "$(printf 'a\nfoo\nbar\n.\ng/foo/s/foo/baz/\\\nd\n,p\nQ\n')" \
    "bar"

report
