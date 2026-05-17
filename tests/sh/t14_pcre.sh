#!/bin/sh
# t14_pcre.sh: comprehensive tests for PCRE2 mode (-P flag)
_current_file="t14_pcre"
. "$(dirname "$0")/../harness.sh"

# -----------------------------------------------------------------------
# Error handling
# -----------------------------------------------------------------------

# Invalid PCRE pattern (unclosed parenthesis) emits ?
run_test "invalid PCRE pattern emits question mark" \
    "$(printf 'a\nfoo\n.\n/foo(/p\nQ\n')" \
    "?" "-P"

# Invalid PCRE pattern causes exit 1
run_test_exit "invalid PCRE pattern exits with code 1" \
    "$(printf 'a\nfoo\n.\n/foo(/p\nQ\n')" \
    1 "-P"

# Loose mode continues after bad PCRE compile; subsequent valid pattern works
run_test "loose mode continues after invalid PCRE pattern" \
    "$(printf 'a\nfoo\n.\n/foo(/p\n/foo/p\nQ\n')" \
    "$(printf '?\nfoo')" "-lP"

# A valid pattern compiled after a failed compile resets state correctly
run_test "valid PCRE compile after failed compile works" \
    "$(printf 'a\nhello\n.\n/[invalid/p\n/hello/p\nQ\n')" \
    "$(printf '?\nhello')" "-lP"

# -----------------------------------------------------------------------
# Pattern reuse
# -----------------------------------------------------------------------

# Empty address pattern // reuses last compiled PCRE pattern
run_test "empty address pattern reuses last PCRE pattern" \
    "$(printf 'a\nfoo1\nbar\nfoo2\n.\n/foo/p\n//p\nQ\n')" \
    "$(printf 'foo1\nfoo2')" "-P"

# Empty substitution pattern s// reuses last PCRE pattern
run_test "empty substitution pattern reuses last PCRE pattern" \
    "$(printf 'a\nfoo\nfoo\n.\n1s/foo/BAR/\n2s//BAZ/p\nQ\n')" \
    "BAZ" "-P"

# -----------------------------------------------------------------------
# PCRE2-specific syntax
# -----------------------------------------------------------------------

# Positive lookahead: match only if followed by a specific string
run_test "PCRE2 positive lookahead in address" \
    "$(printf 'a\nfoo bar\nfoo baz\nfoo qux\n.\n/foo(?= bar)/p\nQ\n')" \
    "foo bar" "-P"

# Negative lookahead: match only if NOT followed by a specific string
run_test "PCRE2 negative lookahead excludes unwanted suffix" \
    "$(printf 'a\nfoobar\nfoo baz\nfoo bar\n.\ng/foo(?! bar)/p\nQ\n')" \
    "$(printf 'foobar\nfoo baz')" "-P"

# Positive lookbehind: match only if preceded by a specific string
run_test "PCRE2 positive lookbehind in global address" \
    "$(printf 'a\nbar42\nfoo42\n.\ng/(?<=foo)\d+/p\nQ\n')" \
    "foo42" "-P"

# Non-greedy quantifier +? stops at the first possible match
run_test "PCRE2 non-greedy quantifier in substitution" \
    "$(printf 'a\n<a><b>\n.\ns/<.*?>/X/gp\nQ\n')" \
    "XX" "-P"

# \w matches word characters (letters, digits, underscore)
run_test "PCRE2 \\w word-character class replaces all tokens" \
    "$(printf 'a\nhello world\n.\ns/\w+/X/gp\nQ\n')" \
    "X X" "-P"

# \s matches whitespace; collapses multiple spaces
run_test "PCRE2 \\s whitespace class collapses spaces" \
    "$(printf 'a\nhello   world\n.\ns/\s+/ /gp\nQ\n')" \
    "hello world" "-P"

# \b word boundary: matches only the whole word, not substrings
run_test "PCRE2 \\b word boundary replaces only whole word" \
    "$(printf 'a\nfoo foobar foobaz\n.\ns/\\bfoo\\b/X/gp\nQ\n')" \
    "X foobar foobaz" "-P"

# (?:...) non-capturing group: does not consume a capture slot
run_test "PCRE2 non-capturing group does not affect capture numbering" \
    "$(printf 'a\nfoobar\n.\ns/(?:foo)(bar)/\\1/p\nQ\n')" \
    "bar" "-P"

# Named capture (?P<name>...) still reachable by number
run_test "PCRE2 named capture is reachable by positional number" \
    "$(printf 'a\n2024-01-15\n.\ns/(?P<y>\\d{4})-(\\d{2})-(\\d{2})/\\3\\/\\2\\/\\1/p\nQ\n')" \
    "15/01/2024" "-P"

# Three capture groups with positional backreferences
run_test "PCRE2 three capture groups reverse-joined" \
    "$(printf 'a\na-b-c\n.\ns/(a)-(b)-(c)/\\3-\\2-\\1/p\nQ\n')" \
    "c-b-a" "-P"

# Possessive quantifier ++: PCRE2-only syntax (ERE/BRE don't have it)
run_test "PCRE2 possessive quantifier matches greedily" \
    "$(printf 'a\nabc\n.\n/a++b/p\nQ\n')" \
    "abc" "-P"

# Alternation | is always active (no backslash needed, unlike BRE)
run_test "PCRE2 alternation matches either branch" \
    "$(printf 'a\ncat\ndog\nbird\n.\ng/cat|dog/p\nQ\n')" \
    "$(printf 'cat\ndog')" "-P"

# \d shorthand matches digits
run_test "PCRE2 digit shorthand substitution" \
    "$(printf 'a\nhello 42 world\n.\ns/\d+/NUM/gp\nQ\n')" \
    "hello NUM world" "-P"

# -----------------------------------------------------------------------
# Unmatched alternation group (PCRE2_UNSET handling)
# -----------------------------------------------------------------------

# When group 1 matches but group 2 is unset, \1 fills in and \2 is empty
run_test "PCRE2 unset alternation group 2 yields empty string" \
    "$(printf 'a\nfoo\n.\ns/(foo)|(bar)/[\\1]/p\nQ\n')" \
    "[foo]" "-P"

# When group 2 matches but group 1 is unset, \2 fills in
run_test "PCRE2 unset alternation group 1 yields empty string" \
    "$(printf 'a\nbar\n.\ns/(foo)|(bar)/[\\2]/p\nQ\n')" \
    "[bar]" "-P"

# -----------------------------------------------------------------------
# Substitution edge cases
# -----------------------------------------------------------------------

# Global substitution with zero-length-capable pattern (a* on "abc"):
# empty match at 0 → X, then "a" advancement, then empty at 2 → X, c suffix
run_test "PCRE2 zero-length global substitution a* on abc" \
    "$(printf 'a\nabc\n.\ns/a*/X/gp\nQ\n')" \
    "XbXc" "-P"

# b* on "abc": empty at 0 → X, then b at 1 → X, empty at 2 → X, c suffix
run_test "PCRE2 zero-length global substitution b* on abc" \
    "$(printf 'a\nabc\n.\ns/b*/X/gp\nQ\n')" \
    "XaXc" "-P"

# nth-occurrence: replace only the 2nd match
run_test "PCRE2 nth-occurrence substitution replaces only 2nd match" \
    "$(printf 'a\nfoo foo foo\n.\ns/foo/X/2p\nQ\n')" \
    "foo X foo" "-P"

# Whole-match & reference
run_test "PCRE2 ampersand references whole match" \
    "$(printf 'a\nhello\n.\ns/ell/[&]/p\nQ\n')" \
    "h[ell]o" "-P"

# -----------------------------------------------------------------------
# Command interactions
# -----------------------------------------------------------------------

# v command (inverse global): keep lines matching a PCRE pattern, delete others
run_test "PCRE2 v command deletes lines not matching digit" \
    "$(printf 'a\nfoo\nbar2\nbaz\n.\nv/\d/d\n,p\nQ\n')" \
    "bar2" "-P"

# g command using PCRE in both the address and the substitution body
run_test "PCRE2 g command uses PCRE in address and body" \
    "$(printf 'a\nfoo1\nfoo2\nbar3\n.\ng/foo\d/s/\d/N/p\nQ\n')" \
    "$(printf 'fooN\nfooN')" "-P"

# Backward address search ?re? with PCRE from end of buffer
run_test "PCRE2 backward search wraps to matching line" \
    "$(printf 'a\nfoo\nbar\nfoo2\n.\n?foo?p\nQ\n')" \
    "foo" "-P"

# -----------------------------------------------------------------------
# Flag interactions
# -----------------------------------------------------------------------

# -P and -l combined: error does not stop execution
run_test "-P -l: loose mode continues after PCRE compile error" \
    "$(printf 'a\nhello\n.\n/hello(/p\n/hello/p\nQ\n')" \
    "$(printf '?\nhello')" "-Pl"

# -P and -n: line numbers prefix printed output
run_test "-P -n: always-number with PCRE pattern" \
    "$(printf 'a\nfoo\nbar\n.\n,p\nQ\n')" \
    "$(printf '1\tfoo\n2\tbar')" "-Pn"

# -P and -e: inline command uses PCRE
run_test "-P -e: inline command with PCRE substitution" \
    "" \
    "X" "-P -e a -e helloworld -e . -e s/\w+/X/ -e ,p"

# -EP mutual exclusion: -E then -P exits 1
run_test_exit "-E and -P are mutually exclusive (-E first)" \
    "$(printf 'q\n')" \
    1 "-EP"

# -PE mutual exclusion: -P then -E exits 1
run_test_exit "-P and -E are mutually exclusive (-P first)" \
    "$(printf 'q\n')" \
    1 "-PE"

report
