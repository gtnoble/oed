#!/bin/sh
# t11_new_commands.sh: test B, N, y, x commands
_current_file="t11_new_commands"
. "$(dirname "$0")/../harness.sh"

# B command reports: current_addr addr_last modified filename
run_test "B command reports buffer state on empty buffer" \
    "$(printf 'B\nQ\n')" \
    "0 0 0 (none)"

run_test "B command reports modified flag after append" \
    "$(printf 'a\nfoo\n.\nB\nQ\n')" \
    "1 1 1 (none)"

run_test "B command reports addr_last correctly" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\nB\nQ\n')" \
    "3 3 1 (none)"

run_test "B command reports current_addr at dot" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2\nB\nQ\n')" \
    "$(printf 'bar\n2 3 1 (none)')"

# N command toggles always_number; subsequent prints include line numbers
run_test "N command enables line-number prefix on print" \
    "$(printf 'N\na\nalpha\nbeta\n.\n,p\nQ\n')" \
    "$(printf '1\talpha\n2\tbeta')"

run_test "N command toggle off disables numbers" \
    "$(printf 'N\nN\na\nfoo\n.\n,p\nQ\n')" \
    "foo"

# y yank and x put
run_test "y yanks lines and x puts after addressed line" \
    "$(printf 'a\nfoo\nbar\n.\n1,2y\n0x\n,p\nQ\n')" \
    "$(printf 'foo\nbar\nfoo\nbar')"

run_test "y yank single line then put" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2y\n0x\n,p\nQ\n')" \
    "$(printf 'bar\nfoo\nbar\nbaz')"

# x puts after the addressed line (default = current line)
run_test "x without address puts after current line" \
    "$(printf 'a\nfoo\nbar\n.\n1y\nx\n,p\nQ\n')" \
    "$(printf 'foo\nbar\nfoo')"


# B with an address is an error
run_test "B with address gives error" \
    "$(printf 'a\nfoo\n.\n1B\nQ\n')" \
    "?"

# B after write: modified resets to 0 and filename is recorded
run_test "B after write shows modified=0 and filename" \
    "$(printf 'a\nfoo\n.\nw %s/b_test.txt\nB\nQ\n' "$_TDIR")" \
    "$(printf '1 1 0 %s/b_test.txt' "$_TDIR")"

# N with an address is an error
run_test "N with address gives error" \
    "$(printf 'a\nfoo\n.\n1N\nQ\n')" \
    "?"

# N numbers l (list) output as well as p
run_test "N numbers l command output" \
    "$(printf 'N\na\nhello\n.\n,l\nQ\n')" \
    "1	hello\$"

# y does not move dot
run_test "y does not move dot" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1y\n.p\nQ\n')" \
    "baz"

# y does not set the modified flag
run_test "y does not set modified flag" \
    "$(printf 'a\nfoo\n.\nw %s/ymod.txt\n1y\nB\nQ\n' "$_TDIR")" \
    "$(printf '1 1 0 %s/ymod.txt' "$_TDIR")"

# y on empty buffer is an error
run_test "y on empty buffer gives error" \
    "$(printf 'y\nQ\n')" \
    "?"

# x with an empty cut buffer is an error
run_test "x with empty cut buffer gives error" \
    "$(printf 'a\nfoo\n.\nx\nQ\n')" \
    "?"

# x moves dot to the last put line
# append 3 lines (dot=3), yank 1,2, put after line 3 -> dot = 3+2 = 5
run_test "x moves dot to last put line" \
    "$(printf 'a\none\ntwo\nthree\n.\n1,2y\n3x\nB\nQ\n')" \
    "5 5 1 (none)"

# K command: list active marks
run_test "K with no marks produces no output" \
    "$(printf 'K\nQ\n')" \
    ""

run_test "K lists all set marks with addresses" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2ka\n1kb\nK\nQ\n')" \
    "$(printf "'a 2\n'b 1")"

run_test "K only shows marks still active after deletion" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1ka\n3kb\n2d\nK\nQ\n')" \
    "$(printf "'a 1\n'b 2")"

# Named yank registers
run_test "named register yank and put" \
    "$(printf 'a\none\ntwo\nthree\n.\n1,2"ay\n3"ax\n,p\nQ\n')" \
    "$(printf 'one\ntwo\nthree\none\ntwo')"

run_test "named and unnamed registers are independent" \
    "$(printf 'a\none\ntwo\nthree\n.\n1"ay\n1,2y\n3"ax\n,p\nQ\n')" \
    "$(printf 'one\ntwo\nthree\none')"

run_test "x without register puts from unnamed register" \
    "$(printf 'a\none\ntwo\n.\n1,2y\n2x\n,p\nQ\n')" \
    "$(printf 'one\ntwo\none\ntwo')"

run_test "register prefix on non-y-or-x command gives error" \
    "$(printf 'a\nfoo\n.\n"ap\nQ\n')" \
    "?"
report
