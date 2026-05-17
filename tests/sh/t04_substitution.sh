#!/bin/sh
# t04_substitution.sh: test s command and flags
_current_file="t04_substitution"
. "$(dirname "$0")/../harness.sh"

# basic substitution
run_test "basic substitution" \
    "$(printf 'a\nhello world\n.\ns/world/earth/\np\nQ\n')" \
    "hello earth"

# substitution with p flag prints result
run_test "substitution p flag prints result" \
    "$(printf 'a\nfoo\n.\ns/foo/bar/p\nQ\n')" \
    "bar"

# global substitution replaces all occurrences
run_test "global substitution replaces all occurrences" \
    "$(printf 'a\naaa\n.\ns/a/b/g\np\nQ\n')" \
    "bbb"

# nth occurrence substitution
run_test "3rd occurrence substitution" \
    "$(printf 'a\naaaa\n.\ns/a/b/3\np\nQ\n')" \
    "aaba"

# 2nd occurrence
run_test "2nd occurrence substitution" \
    "$(printf 'a\naaa\n.\ns/a/b/2\np\nQ\n')" \
    "aba"

# & in replacement stands for matched text
run_test "ampersand in replacement" \
    "$(printf 'a\nhello\n.\ns/hello/[&]/\np\nQ\n')" \
    "[hello]"

# BRE backreference \1 \2
run_test "BRE backreferences swap words" \
    "$(printf 'a\nhello world\n.\ns/\\(hello\\) \\(world\\)/\\2 \\1/\np\nQ\n')" \
    "world hello"

# substitution on range
run_test "substitution on range 1,2" \
    "$(printf 'a\nfoo\nfoo\nbar\n.\n1,2s/foo/baz/\n,p\nQ\n')" \
    "$(printf 'baz\nbaz\nbar')"

# repeated last substitution via s with no args (s followed by bare s)
run_test "re-apply last substitution" \
    "$(printf 'a\nfoo\nfoo\n.\n1s/foo/bar/\n2s\n,p\nQ\n')" \
    "$(printf 'bar\nbar')"

# substitution combined with g and p flags
run_test "s with g and p flags" \
    "$(printf 'a\nabc\n.\ns/[abc]/x/gp\nQ\n')" \
    "xxx"

# substitute empty match (replace nothing adds text)
run_test "substitution changes dot" \
    "$(printf 'a\nfoo\nbar\n.\n1s/foo/baz/\n.p\nQ\n')" \
    "baz"

report
