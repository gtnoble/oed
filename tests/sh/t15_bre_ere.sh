#!/bin/sh
# t15_bre_ere.sh: comprehensive BRE (default) and ERE (-E) regex tests
_current_file="t15_bre_ere"
. "$(dirname "$0")/../harness.sh"

# -----------------------------------------------------------------------
# Error handling
# -----------------------------------------------------------------------

# Invalid BRE pattern (unclosed \() emits ?
run_test "invalid BRE pattern emits question mark" \
    "$(printf 'a\nfoo\n.\n/\\(unclosed/p\nQ\n')" \
    "?"

# Invalid BRE pattern causes exit 1
run_test_exit "invalid BRE pattern exits with code 1" \
    "$(printf 'a\nfoo\n.\n/\\(unclosed/p\nQ\n')" \
    1

# Invalid ERE pattern (unclosed () emits ?
run_test "invalid ERE pattern emits question mark" \
    "$(printf 'a\nfoo\n.\n/(unclosed/p\nQ\n')" \
    "?" "-E"

# Invalid ERE pattern causes exit 1
run_test_exit "invalid ERE pattern exits with code 1" \
    "$(printf 'a\nfoo\n.\n/(unclosed/p\nQ\n')" \
    1 "-E"

# Loose mode continues after bad BRE compile; subsequent valid pattern works
run_test "loose mode continues after invalid BRE pattern" \
    "$(printf 'a\nfoo\n.\n/\\(bad/p\n/foo/p\nQ\n')" \
    "$(printf '?\nfoo')" "-l"

# Loose mode continues after bad ERE compile
run_test "loose mode continues after invalid ERE pattern" \
    "$(printf 'a\nfoo\n.\n/(bad/p\n/foo/p\nQ\n')" \
    "$(printf '?\nfoo')" "-El"

# -----------------------------------------------------------------------
# Pattern reuse
# -----------------------------------------------------------------------

# Empty address pattern // reuses last compiled BRE pattern
run_test "empty address pattern reuses last BRE pattern" \
    "$(printf 'a\nfoo1\nbar\nfoo2\n.\n/foo/p\n//p\nQ\n')" \
    "$(printf 'foo1\nfoo2')"

# Empty address pattern // reuses last compiled ERE pattern
run_test "empty address pattern reuses last ERE pattern" \
    "$(printf 'a\nfoo1\nbar\nfoo2\n.\n/foo/p\n//p\nQ\n')" \
    "$(printf 'foo1\nfoo2')" "-E"

# Empty substitution pattern s// reuses last BRE pattern
run_test "empty substitution pattern reuses last BRE pattern" \
    "$(printf 'a\nfoo\nfoo\n.\n1s/foo/BAR/\n2s//BAZ/p\nQ\n')" \
    "BAZ"

# Empty substitution pattern s// reuses last ERE pattern
run_test "empty substitution pattern reuses last ERE pattern" \
    "$(printf 'a\nfoo\nfoo\n.\n1s/foo/BAR/\n2s//BAZ/p\nQ\n')" \
    "BAZ" "-E"

# -----------------------------------------------------------------------
# BRE-specific syntax
# -----------------------------------------------------------------------

# \{n\} exact interval: only lines with exactly 3 consecutive a's match
run_test "BRE exact interval \\{n\\} matches exactly n repetitions" \
    "$(printf 'a\naaa\naa\na\n.\ng/a\\{3\\}/p\nQ\n')" \
    "aaa"

# \{n,\} minimum interval: lines with 2 or more consecutive a's
run_test "BRE minimum interval \\{n,\\} matches n or more repetitions" \
    "$(printf 'a\naaa\naa\na\n.\ng/a\\{2,\\}/p\nQ\n')" \
    "$(printf 'aaa\naa')"

# \{n,m\} range interval: matches 2 to 3 consecutive a's
run_test "BRE range interval \\{n,m\\} matches between n and m repetitions" \
    "$(printf 'a\naaaa\naaa\naa\na\n.\ng/a\\{2,3\\}/p\nQ\n')" \
    "$(printf 'aaaa\naaa\naa')"

# \(…\) with \1 backreference in the search pattern
run_test "BRE \\(\\) backreference in pattern matches repeated word" \
    "$(printf 'a\nfoo foo\nfoo bar\n.\ng/\\(foo\\).*\\1/p\nQ\n')" \
    "foo foo"

# Two capture groups \1 \2 swapped in substitution
run_test "BRE two capture groups swapped in substitution" \
    "$(printf 'a\nhello world\n.\ns/\\(hello\\) \\(world\\)/\\2 \\1/p\nQ\n')" \
    "world hello"

# ^ and $ used together to match whole-line content
run_test "BRE ^ and \\$ anchors match exact whole-line content" \
    "$(printf 'a\nfoo\nfoo bar\nbarfoo\n.\ng/^foo$/p\nQ\n')" \
    "foo"

# \. matches a literal dot, not any character
run_test "BRE escaped dot matches literal dot only" \
    "$(printf 'a\n3.14\n314\na.b\n.\ng/[0-9]\\.[0-9]/p\nQ\n')" \
    "3.14"

# -----------------------------------------------------------------------
# ERE-specific syntax
# -----------------------------------------------------------------------

# + quantifier: one or more
run_test "ERE + quantifier matches one or more" \
    "$(printf 'a\nfoo\nbr\nf\n.\ng/fo+/p\nQ\n')" \
    "foo" "-E"

# ? quantifier: zero or one (optional character)
run_test "ERE ? quantifier makes character optional" \
    "$(printf 'a\ncolor\ncolour\ncolr\n.\ng/colou?r/p\nQ\n')" \
    "$(printf 'color\ncolour')" "-E"

# {n,m} interval without backslashes
run_test "ERE interval {n,m} without backslashes" \
    "$(printf 'a\naaaa\naaa\naa\na\n.\ng/a{2,3}/p\nQ\n')" \
    "$(printf 'aaaa\naaa\naa')" "-E"

# | alternation across three branches
run_test "ERE | alternation matches any of three branches" \
    "$(printf 'a\ncat\ndog\nbird\nfish\n.\ng/cat|dog|bird/p\nQ\n')" \
    "$(printf 'cat\ndog\nbird')" "-E"

# () grouping with \1 \2 capture in substitution
run_test "ERE () grouping with capture groups swapped in substitution" \
    "$(printf 'a\nhello world\n.\ns/(hello) (world)/\\2 \\1/p\nQ\n')" \
    "world hello" "-E"

# Three capture groups: (a)(b)(c) reversed with \3\2\1
run_test "ERE three capture groups reversed in substitution" \
    "$(printf 'a\na-b-c\n.\ns/(a)-(b)-(c)/\\3-\\2-\\1/p\nQ\n')" \
    "c-b-a" "-E"

# | inside bracket expression is a literal, not alternation
run_test "ERE pipe inside bracket expression is a literal character" \
    "$(printf 'a\na|b\na\nb\n.\ng/[|]/p\nQ\n')" \
    "a|b" "-E"

# ^ and $ anchors work identically to BRE
run_test "ERE ^ and \\$ anchors match exact whole-line content" \
    "$(printf 'a\nfoo\nfoo bar\nbarfoo\n.\ng/^foo$/p\nQ\n')" \
    "foo" "-E"

# -----------------------------------------------------------------------
# POSIX bracket expressions (both BRE and ERE)
# -----------------------------------------------------------------------

# [:alpha:] matches only letter-only lines
run_test "BRE [:alpha:] class matches only alphabetic lines" \
    "$(printf 'a\nhello\n123\nfoo9\n.\ng/^[[:alpha:]]*$/p\nQ\n')" \
    "hello"

# [:digit:] matches only digit-only lines
run_test "BRE [:digit:] class matches only digit lines" \
    "$(printf 'a\nhello\n123\nfoo9\n.\ng/^[[:digit:]]*$/p\nQ\n')" \
    "123"

# [:alnum:] matches letters and digits but not punctuation
run_test "BRE [:alnum:] class matches alphanumeric lines" \
    "$(printf 'a\nfoo123\nhello!\n.\ng/^[[:alnum:]]*$/p\nQ\n')" \
    "foo123"

# [:space:] matches lines containing whitespace
run_test "BRE [:space:] class matches lines containing whitespace" \
    "$(printf 'a\nhello world\nhelloworld\n.\ng/[[:space:]]/p\nQ\n')" \
    "hello world"

# [:upper:] matches lines starting with an uppercase letter
run_test "BRE [:upper:] class matches uppercase-initial lines" \
    "$(printf 'a\nHello\nworld\nFoo\n.\ng/^[[:upper:]]/p\nQ\n')" \
    "$(printf 'Hello\nFoo')"

# [:lower:] matches lines containing any lowercase letter
run_test "BRE [:lower:] class matches lines with a lowercase letter" \
    "$(printf 'a\nhello\nHELLO\n123\n.\ng/[[:lower:]]/p\nQ\n')" \
    "hello"

# [:punct:] matches lines containing a punctuation character
run_test "BRE [:punct:] class matches lines with punctuation" \
    "$(printf 'a\nhello!\nworld\n.\ng/[[:punct:]]/p\nQ\n')" \
    "hello!"

# Negated POSIX class [^[:digit:]] matches non-digit-only lines
run_test "BRE negated [:digit:] class matches non-digit-only lines" \
    "$(printf 'a\nfoo\n123\n.\ng/^[^[:digit:]]*$/p\nQ\n')" \
    "foo"

# Range [a-z] matches lowercase-only lines
run_test "BRE range [a-z] matches lowercase letter lines" \
    "$(printf 'a\nhello\nHELLO\n123\n.\ng/^[a-z]*$/p\nQ\n')" \
    "hello"

# ] as first char in class matches literal ]
run_test "BRE ] as first char in bracket expression matches literal ]" \
    "$(printf 'a\n]hi\nhi\n[hi\n.\ng/[][(]/p\nQ\n')" \
    "$(printf ']hi\n[hi')"

# [:alpha:] also works in ERE
run_test "ERE [:alpha:] class matches only alphabetic lines" \
    "$(printf 'a\nhello\n123\nfoo9\n.\ng/^[[:alpha:]]+$/p\nQ\n')" \
    "hello" "-E"

# -----------------------------------------------------------------------
# Substitution edge cases
# -----------------------------------------------------------------------

# Zero-length BRE global substitution: a* on "abc"
run_test "BRE zero-length global substitution a* on abc" \
    "$(printf 'a\nabc\n.\ns/a*/X/gp\nQ\n')" \
    "XbXc"

# Zero-length BRE global substitution: b* on "abc"
run_test "BRE zero-length global substitution b* on abc" \
    "$(printf 'a\nabc\n.\ns/b*/X/gp\nQ\n')" \
    "XaXc"

# Zero-length ERE global substitution: a* on "abc"
run_test "ERE zero-length global substitution a* on abc" \
    "$(printf 'a\nabc\n.\ns/a*/X/gp\nQ\n')" \
    "XbXc" "-E"

# nth-occurrence BRE: replace only the 2nd match
run_test "BRE nth-occurrence substitution replaces only 2nd match" \
    "$(printf 'a\nfoo foo foo\n.\ns/foo/X/2p\nQ\n')" \
    "foo X foo"

# nth-occurrence ERE: replace only the 2nd match
run_test "ERE nth-occurrence substitution replaces only 2nd match" \
    "$(printf 'a\nfoo foo foo\n.\ns/foo/X/2p\nQ\n')" \
    "foo X foo" "-E"

# & whole-match reference in BRE
run_test "BRE ampersand references entire match in substitution" \
    "$(printf 'a\nhello\n.\ns/ell/[&]/p\nQ\n')" \
    "h[ell]o"

# & whole-match reference in ERE
run_test "ERE ampersand references entire match in substitution" \
    "$(printf 'a\nhello\n.\ns/ell/[&]/p\nQ\n')" \
    "h[ell]o" "-E"

# BRE global substitution replaces all occurrences
run_test "BRE global substitution replaces all occurrences" \
    "$(printf 'a\nfoo foo foo\n.\ns/foo/X/gp\nQ\n')" \
    "X X X"

# ERE global substitution replaces all occurrences
run_test "ERE global substitution replaces all occurrences" \
    "$(printf 'a\nfoo foo foo\n.\ns/foo/X/gp\nQ\n')" \
    "X X X" "-E"

# BRE \1 \2 capture in substitution (already covered above; add \3 variant)
run_test "BRE three capture groups reversed in substitution" \
    "$(printf 'a\na-b-c\n.\ns/\\(a\\)-\\(b\\)-\\(c\\)/\\3-\\2-\\1/p\nQ\n')" \
    "c-b-a"

# -----------------------------------------------------------------------
# Command interactions
# -----------------------------------------------------------------------

# g/re/cmd global command with BRE address and BRE sub body
run_test "BRE g command uses BRE in address and substitution body" \
    "$(printf 'a\nfoo1\nfoo2\nbar3\n.\ng/foo[0-9]/s/[0-9]/N/p\nQ\n')" \
    "$(printf 'fooN\nfooN')"

# v/re/cmd inverse global with BRE: deletes lines not matching a digit
run_test "BRE v command deletes lines not matching digit" \
    "$(printf 'a\nfoo\nbar2\nbaz\n.\nv/[0-9]/d\n,p\nQ\n')" \
    "bar2"

# g/re/cmd with ERE address and substitution body
run_test "ERE g command uses ERE in address and substitution body" \
    "$(printf 'a\nfoo1\nfoo2\nbar3\n.\ng/foo[0-9]/s/[0-9]/N/p\nQ\n')" \
    "$(printf 'fooN\nfooN')" "-E"

# v/re/cmd inverse global with ERE
run_test "ERE v command deletes lines not matching digit" \
    "$(printf 'a\nfoo\nbar2\nbaz\n.\nv/[0-9]/d\n,p\nQ\n')" \
    "bar2" "-E"

# Backward search ?re? with BRE wraps to matching line
run_test "BRE backward search wraps to last matching line" \
    "$(printf 'a\nfoo\nbar\nfoo2\n.\n?foo?p\nQ\n')" \
    "foo"

# Backward search ?re? with ERE
run_test "ERE backward search wraps to last matching line" \
    "$(printf 'a\nfoo\nbar\nfoo2\n.\n?foo?p\nQ\n')" \
    "foo" "-E"

# g command with ERE alternation in address
run_test "ERE g command with alternation in address" \
    "$(printf 'a\ncat\ndog\nbird\n.\ng/cat|bird/s/$/!/p\nQ\n')" \
    "$(printf 'cat!\nbird!')" "-E"

# -----------------------------------------------------------------------
# Flag interactions
# -----------------------------------------------------------------------

# BRE default with -n: line numbers prefix output
run_test "BRE -n flag prefixes output lines with line numbers" \
    "$(printf 'a\nfoo\nbar\n.\ng/foo/p\nQ\n')" \
    "1	foo" "-n"

# ERE with -n: line numbers prefix output
run_test "ERE -E -n flags prefix output lines with line numbers" \
    "$(printf 'a\nfoo\nbar\n.\n,p\nQ\n')" \
    "$(printf '1\tfoo\n2\tbar')" "-En"

# ERE -El: loose mode continues after ERE compile error
run_test "ERE -E -l loose mode continues after compile error" \
    "$(printf 'a\nhello\n.\n/(bad/p\n/hello/p\nQ\n')" \
    "$(printf '?\nhello')" "-El"

# ERE -e: inline command uses ERE pattern
run_test "ERE -e inline command uses ERE substitution" \
    "" \
    "X" "-E -e a -e helloworld -e . -e s/[a-z]+/X/ -e ,p"

# ERE -ElT: error in transaction mode rolls back and exits 1
run_test_exit "ERE -ElT error in transaction mode exits with code 1" \
    "$(printf 'a\nhello\n.\n/(bad/p\nQ\n')" \
    1 "-ElT"

report
