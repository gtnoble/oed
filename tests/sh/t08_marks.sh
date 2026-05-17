#!/bin/sh
# t08_marks.sh: test k command and mark addressing ('x)
_current_file="t08_marks"
. "$(dirname "$0")/../harness.sh"

# mark and print by mark address
run_test "mark line and print via mark address" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2ka\n'\''ap\nQ\n')" \
    "bar"

# mark then use in range
run_test "mark used as range start" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n2kb\n'\''b,3p\nQ\n')" \
    "$(printf 'bar\nbaz')"

# mark survives insertion before it (mark shifts with line)
run_test "mark shifts when line inserted before it" \
    "$(printf 'a\nfoo\nbar\n.\n2ka\n1i\nnew\n.\n'\''ap\nQ\n')" \
    "bar"

# mark used as move destination
run_test "move to mark address" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n3ka\n1m'\''a\n,p\nQ\n')" \
    "$(printf 'bar\nbaz\nfoo')"

report
