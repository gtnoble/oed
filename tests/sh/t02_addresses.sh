#!/bin/sh
# t02_addresses.sh: test all address forms
_current_file="t02_addresses"
. "$(dirname "$0")/../harness.sh"

# absolute address
run_test "absolute line address" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2p\nQ\n')" \
    "bar"

# $ (last line)
run_test "dollar selects last line" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n$p\nQ\n')" \
    "baz"

# . (current line; after append = last)
run_test "dot after append is last line" \
    "$(printf 'a\nfoo\nbar\n.\n.p\nQ\n')" \
    "bar"

# + relative forward
run_test "relative +1 from line 1" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1+1p\nQ\n')" \
    "bar"

# - relative backward
run_test "relative -1 from last line" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n$-1p\nQ\n')" \
    "bar"

# +N shorthand (no explicit dot)
run_test "bare +2 from line 1" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1+2p\nQ\n')" \
    "baz"

# range with comma
run_test "comma range 2,3" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2,3p\nQ\n')" \
    "$(printf 'bar\nbaz')"

# range 1,$ prints everything
run_test "1,dollar prints all lines" \
    "$(printf 'a\nfoo\nbar\n.\n1,$p\nQ\n')" \
    "$(printf 'foo\nbar')"

# , alone means 1,$
run_test "bare comma means 1,dollar" \
    "$(printf 'a\nfoo\nbar\n.\n,p\nQ\n')" \
    "$(printf 'foo\nbar')"

# regex forward search
run_test "forward regex address" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n/bar/p\nQ\n')" \
    "bar"

# regex backward search
run_test "backward regex address" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n?bar?p\nQ\n')" \
    "bar"

# semicolon address sets dot before second addr is evaluated
run_test "semicolon sets dot to first addr" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1;+1p\nQ\n')" \
    "$(printf 'foo\nbar')"

report
