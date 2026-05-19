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


# = with range prints both resolved addresses
run_test "= with range prints both resolved addresses" \
    "$(printf 'a\none\ntwo\nthree\n.\n1,3=\nQ\n')" \
    "1 3"

run_test "= with single address prints that line number" \
    "$(printf 'a\none\ntwo\nthree\n.\n2=\nQ\n')" \
    "2"

run_test "= with no address prints addr_last" \
    "$(printf 'a\none\ntwo\nthree\n.\n=\nQ\n')" \
    "3"

run_test "bare comma range with = prints 1 and addr_last" \
    "$(printf 'a\none\ntwo\nthree\n.\n,=\nQ\n')" \
    "1 3"

# @hash addressing
run_test "@hash finds the unique line with matching content" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n@039d0140p\nQ\n')" \
    "bar"

run_test "@hash in range with numeric second address" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n@03d1014f,3p\nQ\n')" \
    "$(printf 'foo\nbar\nbaz')"

run_test "@hash as second address in range" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1,@039d0140p\nQ\n')" \
    "$(printf 'foo\nbar')"

run_test "@hash with positive offset" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n@03d1014f+2p\nQ\n')" \
    "baz"

run_test "@hash with negative offset" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n@03ad0148-1p\nQ\n')" \
    "bar"

run_test "@hash as destination of m command" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n3m@03d1014f\n,p\nQ\n')" \
    "$(printf 'foo\nbaz\nbar')"

run_test "@hash ambiguous (duplicate content) returns error" \
    "$(printf 'a\nfoo\nfoo\nbaz\n.\n@03d1014fp\nQ\n')" \
    "?" "-l"

run_test "@hash no match returns error" \
    "$(printf 'a\nfoo\nbar\n.\n@deadbeefp\nQ\n')" \
    "?" "-l"

run_test "@hash invalid hex digit returns error" \
    "$(printf 'a\nfoo\n.\n@0000000zp\nQ\n')" \
    "?" "-l"
report
