#!/bin/sh
# t06_file_io.sh: test e, r, w, W commands
_current_file="t06_file_io"
. "$(dirname "$0")/../harness.sh"

WFILE="$_TDIR/test_out.txt"
RFILE="$_TDIR/test_in.txt"
AFILE="$_TDIR/test_append.txt"

# Write file and verify content on disk
run_test_file "w writes buffer to file" \
    "$(printf 'a\nhello\nworld\n.\nw %s\nQ\n' "$WFILE")" \
    "$(printf 'hello\nworld')" \
    "$WFILE"

# Read file contents into buffer after w
run_test "r reads file into buffer after current line" \
    "$(printf 'a\nhello\nworld\n.\nw %s\nr %s\n,p\nQ\n' "$WFILE" "$WFILE")" \
    "$(printf 'hello\nworld\nhello\nworld')"

# r inserts after addressed line (0r = prepend)
run_test "0r inserts file before first line" \
    "$(printf 'a\nfoo\n.\nw %s\na\nbar\n.\n0r %s\n,p\nQ\n' "$WFILE" "$WFILE")" \
    "$(printf 'foo\nfoo\nbar')"

# W appends to existing file
run_test_file "W appends to existing file" \
    "$(printf 'a\nfoo\n.\nw %s\na\nbar\n.\n2,2W %s\nQ\n' "$AFILE" "$AFILE")" \
    "$(printf 'foo\nbar')" \
    "$AFILE"

# w range writes subset
run_test_file "w with range writes only those lines" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1,2w %s\nQ\n' "$WFILE")" \
    "$(printf 'foo\nbar')" \
    "$WFILE"

# e command replaces buffer with file
printf 'one\ntwo\n' > "$RFILE"
run_test "e command loads file replacing buffer" \
    "$(printf 'a\nold\n.\ne %s\n,p\nQ\n' "$RFILE")" \
    "$(printf 'one\ntwo')"

report
