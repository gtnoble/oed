#!/bin/sh
# t09_regex.sh: test BRE (default) and ERE (-E flag) regex behaviour
_current_file="t09_regex"
. "$(dirname "$0")/../harness.sh"

# BRE: dot matches any char
run_test "BRE dot matches any character" \
    "$(printf 'a\nfoo\nbar\n.\n/f.o/p\nQ\n')" \
    "foo"

# BRE: * quantifier
run_test "BRE star quantifier" \
    "$(printf 'a\nfoo\nbr\n.\n/fo*/p\nQ\n')" \
    "foo"

# BRE: ^ anchor
run_test "BRE caret anchor matches line start" \
    "$(printf 'a\nfoo\nbarfoo\n.\n/^foo/p\nQ\n')" \
    "foo"

# BRE: $ anchor
run_test "BRE dollar anchor matches line end" \
    "$(printf 'a\nfoobar\nfoo\n.\n/foo$/p\nQ\n')" \
    "foo"

# BRE: character class
run_test "BRE character class" \
    "$(printf 'a\ncat\ndog\n.\n/[cd]at/p\nQ\n')" \
    "cat"

# BRE: negated character class
run_test "BRE negated character class" \
    "$(printf 'a\ncat\nrat\n.\n/[^c]at/p\nQ\n')" \
    "rat"

# ERE: + quantifier
run_test "ERE plus quantifier matches one or more" \
    "$(printf 'a\nfoo\nbr\n.\n/fo+/p\nQ\n')" \
    "foo" "-E"

# ERE: ? quantifier (optional)
run_test "ERE question mark makes char optional" \
    "$(printf 'a\nfoo\nfo\n.\n/fo?o/p\nQ\n')" \
    "foo" "-E"

# ERE: | alternation (global to get both)
run_test "ERE pipe alternation matches either" \
    "$(printf 'a\ncat\ndog\nbird\n.\ng/cat|dog/p\nQ\n')" \
    "$(printf 'cat\ndog')" "-E"

# ERE: grouping with ()
run_test "ERE grouping and alternation" \
    "$(printf 'a\nfoobar\nfoobaz\nother\n.\ng/foo(bar|baz)/p\nQ\n')" \
    "$(printf 'foobar\nfoobaz')" "-E"

# BRE grouping with \( \) and backreference in substitution
run_test "BRE backreference in substitution" \
    "$(printf 'a\nhello world\n.\ns/\\(hello\\) \\(world\\)/\\2 \\1/\np\nQ\n')" \
    "world hello"

# Empty pattern reuses last compiled pattern
run_test "empty regex reuses last compiled pattern" \
    "$(printf 'a\nfoo\nfoo2\n.\n/foo/p\n//p\nQ\n')" \
    "$(printf 'foo\nfoo2')"

report
