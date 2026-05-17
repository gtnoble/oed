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

# -T: transaction mode rolls back on error, exits 2
run_test_exit "transaction mode exits 2 on error" \
    "$(printf 'a\nline1\n.\n999p\n')" \
    "2" "-T"

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
report
