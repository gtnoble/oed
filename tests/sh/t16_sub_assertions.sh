#!/bin/sh
# t16_sub_assertions.sh: tests for substitution assertion features:
#   =N (exact count), D (dry-run), ! (all-or-nothing), ~re~ (verify pattern),
#   and substitution count in OK token.

_current_file="t16_sub_assertions"
. tests/harness.sh

# --- =N exact-count assertion ---

run_test "=1 exact count: succeeds when count matches" \
    "$(printf 'a\nfoo\n.\ns/foo/baz/=1\n.p\nQ\n')" \
    "baz"

run_test "=1 exact count: fails (no change) when zero lines match" \
    "$(printf 'a\nfoo\n.\ns/xxx/baz/=1\n.p\nQ\n')" \
    "$(printf '?\nfoo')" \
    "-l"

run_test "=2 exact count: fails and rolls back when only one line matched" \
    "$(printf 'a\nfoo\n.\ns/foo/baz/=2\n.p\nQ\n')" \
    "$(printf '?\nfoo')" \
    "-l"

run_test "=2 exact count: succeeds when exactly two lines match" \
    "$(printf 'a\nfoo\nfoo\n.\n1,2s/foo/baz/=2\n,p\nQ\n')" \
    "$(printf 'baz\nbaz')"

run_test "=1 exact count: fails and rolls back when two lines matched" \
    "$(printf 'a\nfoo\nfoo\n.\n1,2s/foo/baz/=1\n,p\nQ\n')" \
    "$(printf '?\nfoo\nfoo')" \
    "-l"

run_test "=1 combined with global g flag: counts substituted lines not occurrences" \
    "$(printf 'a\nfoo foo\n.\ns/foo/baz/g=1\n.p\nQ\n')" \
    "baz baz"

# --- D dry-run ---

run_test "D dry-run: prints substituted text without modifying buffer" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/D\n.p\nQ\n')" \
    "$(printf 'bar\nfoo')"

run_test "D dry-run: no match still gives error" \
    "$(printf 'a\nfoo\n.\ns/xxx/bar/D\n.p\nQ\n')" \
    "$(printf '?\nfoo')" \
    "-l"

run_test "D dry-run: with range prints all would-be results without modifying buffer" \
    "$(printf 'a\nfoo\nfoo\n.\n1,2s/foo/bar/D\n,p\nQ\n')" \
    "$(printf 'bar\nbar\nfoo\nfoo')"

# --- ! all-or-nothing ---

run_test "! all-or-nothing: succeeds when every line in range matches" \
    "$(printf 'a\nfoo\nfoo\n.\n1,2s/foo/bar/!\n,p\nQ\n')" \
    "$(printf 'bar\nbar')"

run_test "! all-or-nothing: fails and rolls back when not all lines match" \
    "$(printf 'a\nfoo\nbar\n.\n1,2s/foo/baz/!\n,p\nQ\n')" \
    "$(printf '?\nfoo\nbar')" \
    "-l"

run_test "! all-or-nothing: single-line range always succeeds or matches normal s" \
    "$(printf 'a\nfoo\n.\ns/foo/baz/!\n.p\nQ\n')" \
    "baz"

run_test "! all-or-nothing: fails on zero matches in range" \
    "$(printf 'a\nfoo\nbar\n.\n1,2s/xxx/baz/!\n,p\nQ\n')" \
    "$(printf '?\nfoo\nbar')" \
    "-l"

# --- ~re~ result verify pattern ---

run_test "verify pattern: succeeds when result matches" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/~^bar$~\n.p\nQ\n')" \
    "bar"

run_test "verify pattern: fails and rolls back when result does not match" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/~^foo$~\n.p\nQ\n')" \
    "$(printf '?\nfoo')" \
    "-l"

run_test "verify pattern: combined with p display flag" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/p~^bar$~\n.p\nQ\n')" \
    "$(printf 'bar\nbar')"

run_test "verify pattern: combined with =1 exact count" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/=1~^bar$~\n.p\nQ\n')" \
    "bar"

# --- Substitution count in OK token ---

run_test "OK token includes 1subs for single substitution" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/\nQ\n')" \
    "$(printf 'OK 1\nOK 1 1subs')" \
    "-A"

run_test "OK token includes 2subs for two-line substitution" \
    "$(printf 'a\nfoo\nfoo\n.\n1,2s/foo/bar/\nQ\n')" \
    "$(printf 'OK 2\nOK 2 2subs')" \
    "-A"

run_test "OK token after non-s command shows no subs count" \
    "$(printf 'a\nfoo\n.\n.p\nQ\n')" \
    "$(printf 'OK 1\nfoo\nOK 1')" \
    "-A"

report
