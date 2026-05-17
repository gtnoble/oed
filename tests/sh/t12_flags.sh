#!/bin/sh
# t12_flags.sh: test -l (loose) and -T (transaction) flags
_current_file="t12_flags"
. "$(dirname "$0")/../harness.sh"

# -l: loose mode continues past ERR-level errors
run_test "loose mode prints question mark and continues" \
    "$(printf '999p\na\nhello\n.\n,p\nQ\n')" \
    "$(printf '?\nhello')" "-l"

# -l: multiple errors all continue
run_test "loose mode tolerates multiple errors" \
    "$(printf '999p\n888p\na\nok\n.\n,p\nQ\n')" \
    "$(printf '?\n?\nok')" "-l"

# -T: transaction mode rolls back on error, exits 1
run_test_exit "transaction mode exits 1 on error" \
    "$(printf 'a\nline1\n.\n999p\n')" \
    "1" "-T"

# -T: on error, output shows ? and stops
run_test "transaction mode outputs question mark on error" \
    "$(printf 'a\nline1\n.\n999p\n')" \
    "?" "-T"

# -T: clean run exits 0
run_test_exit "transaction mode exits 0 on clean run" \
    "$(printf 'a\nok\n.\n,p\nQ\n')" \
    "0" "-T"

# -E: ERE mode is active from the start
run_test "ERE flag enables extended regex globally" \
    "$(printf 'a\nfoo\nbar\n.\n/fo+/p\nQ\n')" \
    "foo" "-E"


# -l exits 0 even when errors occurred (loose never calls quit(2))
run_test_exit "loose mode exits 0 even with errors" \
    "$(printf '999p\nQ\n')" \
    "0" "-l"

# -n: always-number startup flag
run_test "-n flag numbers all printed lines" \
    "$(printf 'a\nfoo\nbar\n.\n,p\nQ\n')" \
    "$(printf '1\tfoo\n2\tbar')" "-n"

run_test "-n and -s can be combined" \
    "$(printf 'a\nfoo\n.\n,n\nQ\n')" \
    "$(printf '1\tfoo')" "-n"

# -e: inline command string
run_test "-e executes inline commands without stdin input" \
    "" \
    "foo" "-e a -e foo -e . -e ,p"

run_test "multiple -e flags run in order" \
    "" \
    "$(printf 'foo\nbar')" "-e a -e foo -e bar -e . -e ,p"

# -A: per-command success token
run_test "-A prints OK after each successful command" \
    "$(printf 'a\nfoo\n.\n,p\nQ\n')" \
    "$(printf 'OK 1\nfoo\nOK 1')" "-A"

run_test "-A does not print OK after a failed command" \
    "$(printf 'a\nfoo\n.\n999p\n,p\nQ\n')" \
    "$(printf 'OK 1\n?\nfoo\nOK 1')" "-A -l"

run_test_exit "-A does not change exit code on success" \
    "$(printf 'a\nfoo\n.\nQ\n')" \
    "0" "-A"
report

# -T: deferred write — w is a no-op until q
TXFILE="$_TDIR/tx_out.txt"

run_test_file "-T: clean run writes file at exit" \
    "$(printf 'a\nhello\n.\nw %s\n' "$TXFILE")" \
    "hello" \
    "$TXFILE" "-T"

rm -f "$TXFILE"
run_test_file "-T: error before w leaves file untouched" \
    "$(printf '999p\na\nfoo\n.\nw %s\n' "$TXFILE")" \
    "" \
    "$TXFILE" "-T"

rm -f "$TXFILE"
run_test_file "-T: error after w leaves file untouched" \
    "$(printf 'a\nfoo\n.\nw %s\n999p\n' "$TXFILE")" \
    "" \
    "$TXFILE" "-T"

run_test_exit "-T: clean run exits 0" \
    "$(printf 'a\nok\n.\nw %s\n' "$TXFILE")" \
    "0" "-T"

run_test_exit "-T: error exits 1 and file is untouched" \
    "$(printf 'a\nok\n.\nw %s\n999p\n' "$TXFILE")" \
    "1" "-T"

TXFILE2="$_TDIR/tx_out2.txt"
run_test_file "-T: multiple w all commit on clean run" \
    "$(printf 'a\nfoo\nbar\n.\n1w %s\n1,2w %s\n' "$TXFILE" "$TXFILE2")" \
    "$(printf 'foo\nbar')" \
    "$TXFILE2" "-T"

# -T: shell escapes forbidden
run_test "-T: shell escape ! is forbidden" \
    "$(printf '!echo hi\n')" \
    "?" "-T"

run_test_exit "-T: shell escape ! exits 1" \
    "$(printf '!echo hi\n')" \
    "1" "-T"

run_test "-T: r shell command is forbidden" \
    "$(printf 'a\nfoo\n.\nr !echo bar\n,p\n')" \
    "$(printf 'OK 1\n?')" "-T -A"

run_test "-T: e shell command is forbidden" \
    "$(printf 'a\nfoo\n.\ne !echo bar\n')" \
    "$(printf 'OK 1\n?')" "-T -A"

# -lT: continue past errors; commit only if all commands clean
run_test_exit "-lT: exits 0 on clean run" \
    "$(printf 'a\nhello\n.\nw %s\n' "$TXFILE")" \
    "0" "-l -T"

rm -f "$TXFILE"
run_test_exit "-lT: exits 1 when any error occurred" \
    "$(printf 'a\nhello\n.\n999p\nw %s\n' "$TXFILE")" \
    "1" "-l -T"

rm -f "$TXFILE"
run_test_file "-lT: file not written when any error occurred" \
    "$(printf 'a\nhello\n.\n999p\nw %s\n' "$TXFILE")" \
    "" \
    "$TXFILE" "-l -T"

run_test "-lT: continues past all errors" \
    "$(printf 'a\nhello\n.\n999p\n888p\na\nworld\n.\n,p\n')" \
    "$(printf '?\n?\nhello\nworld')" "-l -T"

run_test_file "-lT: file written when all commands clean" \
    "$(printf 'a\nhello\n.\nw %s\n' "$TXFILE")" \
    "hello" \
    "$TXFILE" "-l -T"

# -M: implies -s -A -v -l -T
run_test_exit "-M: exits 0 on clean run" \
    "$(printf 'a\nhello\n.\nw %s\n' "$TXFILE")" \
    "0" "-M"

run_test_file "-M: writes file on clean run" \
    "$(printf 'a\nhello\n.\nw %s\n' "$TXFILE")" \
    "hello" \
    "$TXFILE" "-M"

rm -f "$TXFILE"
run_test_exit "-M: exits 1 when any error occurred" \
    "$(printf 'a\nhello\n.\n999p\nw %s\n' "$TXFILE")" \
    "1" "-M"

rm -f "$TXFILE"
run_test_file "-M: file not written when error occurred" \
    "$(printf 'a\nhello\n.\n999p\nw %s\n' "$TXFILE")" \
    "" \
    "$TXFILE" "-M"

run_test "-M: emits OK after each successful command" \
    "$(printf 'a\nhello\n.\n,p\n')" \
    "$(printf 'OK 1\nhello\nOK 1')" "-M"

run_test "-M: continues past errors and emits ? for each" \
    "$(printf 'a\nhello\n.\n999p\na\nworld\n.\n,p\n')" \
    "$(printf 'OK 1\n?\nOK 2\nhello\nworld\nOK 2')" "-M"

run_test "-M: shell escape is forbidden" \
    "$(printf '!echo hi\n')" \
    "?" "-M"

run_test "-M: does not enable persistent line numbering" \
    "$(printf 'a\nfoo\n.\n,p\n')" \
    "$(printf 'OK 1\nfoo\nOK 1')" "-M"

run_test "-M: implies ERE so + quantifier works without -E" \
    "$(printf 'a\nfoo\nbr\n.\n/fo+/p\n')" \
    "$(printf 'OK 2\nfoo\nOK 1')" "-M"

run_test "-M: implies ERE so grouping and alternation work" \
    "$(printf 'a\ncat\ndog\nbird\n.\ng/cat|dog/p\n')" \
    "$(printf 'OK 3\ncat\ndog\nOK 2')" "-M"

# transaction + global command interaction
rm -f "$TXFILE"
run_test_file "-lT: global command succeeds, file written" \
    "$(printf 'a\nfoo\nbar\n.\ng/foo/s/foo/baz/\nw %s\n' "$TXFILE")" \
    "$(printf 'baz\nbar')" \
    "$TXFILE" "-l -T"

rm -f "$TXFILE"
run_test_file "-lT: mutation before failing global rolled back, file not written" \
    "$(printf 'a\nfoo\nbar\n.\ns/foo/baz/\ng/bar/999p\nw %s\n' "$TXFILE")" \
    "" \
    "$TXFILE" "-l -T"

rm -f "$TXFILE"
run_test_file "-lT: first global rolled back when second global fails, file not written" \
    "$(printf 'a\nfoo\nbar\n.\ng/foo/s/foo/baz/\ng/bar/999p\nw %s\n' "$TXFILE")" \
    "" \
    "$TXFILE" "-l -T"

rm -f "$TXFILE"
run_test_file "-M: global command succeeds, file written" \
    "$(printf 'a\nfoo\nbar\n.\ng/foo/s/foo/baz/\nw %s\n' "$TXFILE")" \
    "$(printf 'baz\nbar')" \
    "$TXFILE" "-M"

# -R: read-only mode
_RO_FILE="$_TDIR/ro_source.txt"
printf 'alpha\nbeta\ngamma\n' > "$_RO_FILE"

run_test "-R: append is rejected" \
    "$(printf 'a\nQ\n')" \
    "?" "-R -l"

run_test "-R: delete is rejected" \
    "$(printf '1d\nQ\n')" \
    "?" "-R -l $_RO_FILE"

run_test "-R: substitution is rejected" \
    "$(printf 's/alpha/new/\nQ\n')" \
    "?" "-R -l $_RO_FILE"

run_test "-R: write is rejected" \
    "$(printf 'w /dev/null\nQ\n')" \
    "?" "-R -l $_RO_FILE"

run_test "-R: shell escape is rejected" \
    "$(printf '!echo hi\nQ\n')" \
    "?" "-R -l"

run_test "-R: print is allowed" \
    "$(printf ',p\nQ\n')" \
    "$(printf 'alpha\nbeta\ngamma')" "-R $_RO_FILE"

run_test "-R: = is allowed" \
    "$(printf '=\nQ\n')" \
    "3" "-R $_RO_FILE"

run_test "-R: search address is allowed" \
    "$(printf '/beta/p\nQ\n')" \
    "beta" "-R $_RO_FILE"

report
