#!/bin/sh
# t07_undo.sh: test u (undo) command
_current_file="t07_undo"
. "$(dirname "$0")/../harness.sh"

# undo a deletion: ,p before undo shows one line; ,p after undo shows both
run_test "undo restores deleted line" \
    "$(printf 'a\nfoo\nbar\n.\n2d\n,p\nu\n,p\nQ\n')" \
    "$(printf 'foo\nfoo\nbar')"

# undo an insertion
run_test "undo removes appended line" \
    "$(printf 'a\nfoo\n.\na\nbar\n.\nu\n,p\nQ\n')" \
    "foo"

# undo a substitution
run_test "undo reverts substitution" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/\nu\n,p\nQ\n')" \
    "foo"

# double undo (undo the undo re-applies the change)
run_test "double undo re-applies change" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/\nu\nu\n,p\nQ\n')" \
    "bar"

# undo a move
run_test "undo reverts move" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1m3\nu\n,p\nQ\n')" \
    "$(printf 'foo\nbar\nbaz')"

# undo a copy
run_test "undo reverts copy" \
    "$(printf 'a\nfoo\nbar\n.\n1t2\nu\n,p\nQ\n')" \
    "$(printf 'foo\nbar')"

report
