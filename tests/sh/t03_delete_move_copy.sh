#!/bin/sh
# t03_delete_move_copy.sh: test d, m, t (copy), j commands
_current_file="t03_delete_move_copy"
. "$(dirname "$0")/../harness.sh"

# delete single line
run_test "delete line 2" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2d\n,p\nQ\n')" \
    "$(printf 'foo\nbaz')"

# delete range
run_test "delete range 1,2" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1,2d\n,p\nQ\n')" \
    "baz"

# delete all
run_test "delete all lines leaves empty buffer" \
    "$(printf 'a\nfoo\nbar\n.\n,d\nB\nQ\n')" \
    "0 0 1 1 (none)"

# move line forward
run_test "move line 1 to after line 3" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1m3\n,p\nQ\n')" \
    "$(printf 'bar\nbaz\nfoo')"

# move line backward
run_test "move line 3 to after line 0" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n3m0\n,p\nQ\n')" \
    "$(printf 'baz\nfoo\nbar')"

# move range
run_test "move range 2,3 to after line 0" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2,3m0\n,p\nQ\n')" \
    "$(printf 'bar\nbaz\nfoo')"

# copy (t command) single line
run_test "copy line 1 to after line 2" \
    "$(printf 'a\nfoo\nbar\n.\n1t2\n,p\nQ\n')" \
    "$(printf 'foo\nbar\nfoo')"

# copy range
run_test "copy range 1,2 to after line 3" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1,2t3\n,p\nQ\n')" \
    "$(printf 'foo\nbar\nbaz\nfoo\nbar')"

# join two lines
run_test "join lines 1 and 2" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1,2j\n,p\nQ\n')" \
    "$(printf 'foobar\nbaz')"

# join three lines
run_test "join lines 1,2,3" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1,3j\n,p\nQ\n')" \
    "foobarbaz"

report
