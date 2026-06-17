#!/bin/sh
# t17_multiline.sh: tests for multi-line regex matching and
#   \n / \t escapes in substitution replacement text.

_current_file="t17_multiline"
. "$(dirname "$0")/../harness.sh"

# --- Phase 1: \n and \t in replacement text ---

run_test "\\n in replacement splits a line" \
    "$(printf 'a\nhello world\n.\ns/world/first\\nsecond/\n,p\nQ\n')" \
    "$(printf 'hello first\nsecond')"

run_test "\\t in replacement inserts a tab" \
    "$(printf 'a\nhello world\n.\ns/ /\\t/\np\nQ\n')" \
    "hello	world"

run_test "\\n with \\1 backreference splits line" \
    "$(printf 'a\nhello world\n.\ns/\\(hello\\) \\(world\\)/\\1\\n\\2/\n,p\nQ\n')" \
    "$(printf 'hello\nworld')"

run_test "unrecognized escapes preserved (\\x -> x)" \
    "$(printf 'a\nhello\n.\ns/hello/\\x y\\z/\np\nQ\n')" \
    "x yz"

# --- Phase 2: Multi-line regex matching (requires -P for PCRE2) ---

run_test "multi-line match: replace two lines with one" \
    "$(printf 'a\nAAA\nBBB\n.\n1,2s/AAA\\nBBB/FOUND/\n,p\nQ\n')" \
    "FOUND" \
    "-P"

run_test "multi-line match: replace one line with two" \
    "$(printf 'a\nhello world\n.\n1s/hello world/line1\\nline2/\n,p\nQ\n')" \
    "$(printf 'line1\nline2')" \
    "-P"

run_test "multi-line match: replace two lines with two different" \
    "$(printf 'a\nalpha\nbeta\n.\n1,2s/alpha\\nbeta/GREEK\\nLETTERS/\n,p\nQ\n')" \
    "$(printf 'GREEK\nLETTERS')" \
    "-P"

run_test "multi-line global flag: replace two pairs" \
    "$(printf 'a\nAAA\nBBB\nAAA\nBBB\n.\n1,4s/AAA\\nBBB/FOUND/g\n,p\nQ\n')" \
    "$(printf 'FOUND\nFOUND')" \
    "-P"

run_test "multi-line in larger range: middle two of three" \
    "$(printf 'a\none\nAAA\nBBB\nfour\n.\n1,4s/AAA\\nBBB/FOUND/\n,p\nQ\n')" \
    "$(printf 'one\nFOUND\nfour')" \
    "-P"

# --- Multi-line with assertion suffixes ---

run_test "multi-line =1 exact count: succeeds" \
    "$(printf 'a\nAAA\nBBB\n.\n1,2s/AAA\\nBBB/FOUND/=1\n,p\nQ\n')" \
    "FOUND" \
    "-P -l"

run_test "multi-line =2 exact count: fails when only one match" \
    "$(printf 'a\nAAA\nBBB\n.\n1,2s/AAA\\nBBB/FOUND/=2\n,p\nQ\n')" \
    "$(printf '?\nAAA\nBBB')" \
    "-P -l"

run_test "multi-line D dry-run: prints result, buffer unchanged" \
    "$(printf 'a\nAAA\nBBB\n.\n1,2s/AAA\\nBBB/FOUND/D\n,p\nQ\n')" \
    "$(printf 'FOUND\nAAA\nBBB')" \
    "-P"

run_test "multi-line ! all-or-nothing: succeeds with match" \
    "$(printf 'a\nAAA\nBBB\n.\n1,2s/AAA\\nBBB/FOUND/!\n,p\nQ\n')" \
    "FOUND" \
    "-P"

run_test "multi-line ! fails when no match" \
    "$(printf 'a\nAAA\nCCC\n.\n1,2s/AAA\\nBBB/FOUND/!\n,p\nQ\n')" \
    "$(printf '?\nAAA\nCCC')" \
    "-P -l"

# --- PCRE2 extended features ---

run_test "multi-line with escaped parens in pattern" \
    "$(printf 'a\nint foo(\n\tint x\n)\n.\n1,3s/int foo\\(\\n.*\\n\\)/LONG foo()/\n,p\nQ\n')" \
    "LONG foo()" \
    "-P"

run_test "single-line s works with -P flag" \
    "$(printf 'a\nhello\nworld\n.\n1s/hello/HI/\n,p\nQ\n')" \
    "$(printf 'HI\nworld')" \
    "-P"

report
