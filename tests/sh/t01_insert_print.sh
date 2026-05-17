#!/bin/sh
# t01_insert_print.sh: test a, i, c, p, l, n commands
_current_file="t01_insert_print"
. "$(dirname "$0")/../harness.sh"

# append and print
run_test "append single line and print" \
    "$(printf 'a\nhello\n.\np\nQ\n')" \
    "hello"

# append multiple lines, print all
run_test "append multiple lines and range print" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n,p\nQ\n')" \
    "$(printf 'foo\nbar\nbaz')"

# insert before current line
run_test "insert before line 2" \
    "$(printf 'a\nfoo\nbaz\n.\n2i\nbar\n.\n,p\nQ\n')" \
    "$(printf 'foo\nbar\nbaz')"

# change a line
run_test "change line 2" \
    "$(printf 'a\nfoo\nbar\n.\n2c\nbaz\n.\n,p\nQ\n')" \
    "$(printf 'foo\nbaz')"

# print with line numbers (n command)
run_test "numbered print via n command" \
    "$(printf 'a\nfoo\nbar\n.\n,n\nQ\n')" \
    "$(printf '1\tfoo\n2\tbar')"

# list command escapes tab and shows $
run_test "list command shows tab as backslash-t and dollar at EOL" \
    "$(printf 'a\n\thello\n.\n,l\nQ\n')" \
    "$(printf '\\thello$')"

# print last line via $
run_test "dollar address prints last line" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n$p\nQ\n')" \
    "baz"

# print current line via dot
run_test "dot address after append is last line" \
    "$(printf 'a\nfoo\nbar\n.\n.p\nQ\n')" \
    "bar"

# change multiple lines to one
run_test "change range to single line" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1,2c\nreplaced\n.\n,p\nQ\n')" \
    "$(printf 'replaced\nbaz')"

# insert at line 0 (before all)
run_test "insert at 0 prepends to buffer" \
    "$(printf 'a\nfoo\n.\n0i\nfirst\n.\n,p\nQ\n')" \
    "$(printf 'first\nfoo')"

report
