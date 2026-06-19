# t18_search_context_literal.sh: tests for S (search), R (replace-literal),
# -L (literal mode), and -C (auto-context) features.

. "$(dirname "$0")/../harness.sh"

# --- S command (search) ---

run_test "S: basic search prints matching lines" \
    "$(printf 'a\none\ntwo\nthree\n.\nS/o/\nQ\n')" \
    "$(printf 'one\ntwo\n')"

run_test "S: search with explicit range" \
    "$(printf 'a\none\ntwo\nthree\n.\n2,3S/e/\nQ\n')" \
    "$(printf 'three\n')"

run_test "S: search with no matches produces no output" \
    "$(printf 'a\none\ntwo\n.\nS/xyz/\nQ\n')" \
    ""

run_test "S: search respects -n flag (line numbers)" \
    "$(printf 'a\none\ntwo\nthree\n.\nS/o/\nQ\n')" \
    "$(printf '1\tone\n2\ttwo\n')" \
    "-n"

run_test "S: dot is unchanged after S" \
    "$(printf 'a\none\ntwo\nthree\n.\nS/o/\n.p\nQ\n')" \
    "$(printf 'one\ntwo\nthree\n')"

# --- R command (replace literal) ---

run_test "R: basic literal replacement" \
    "$(printf 'a\nhello world\n.\nR/world/earth/\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: literal . does not match any character (unchanged line -- error because no match)" \
    "$(printf 'a\nhello\n.\nR/.l/HI/\np\nQ\n')" \
    "?"

run_test "R: literal * matches literal asterisk" \
    "$(printf 'a\nfoo*bar\n.\nR/o*/XX/\n.p\nQ\n')" \
    "$(printf 'foXXbar\n')"

run_test "R: g flag replaces all occurrences" \
    "$(printf 'a\naa bb aa\n.\nR/aa/XX/g\n.p\nQ\n')" \
    "$(printf 'XX bb XX\n')"

run_test "R: =1 exact count assertion succeeds" \
    "$(printf 'a\nhello world\n.\nR/world/earth/=1\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: =0 exact count assertion fails when match exists" \
    "$(printf 'a\nhello world\n.\nR/world/earth/=0\n.p\nQ\n')" \
    "?"

run_test "R: ! all-or-nothing succeeds when all lines match" \
    "$(printf 'a\nhello\nworld\n.\n1,2R/o/O/!\np\nQ\n')" \
    "$(printf 'wOrld\n')"

# After R/o/O/! on 1,2: hellO, wOrld. Dot is at last sub (line 2). p prints line 2.

run_test "R: D dry-run prints without modifying buffer" \
    "$(printf 'a\nhello world\n.\nR/world/earth/D\n.p\nQ\n')" \
    "$(printf 'hello earth\nhello world\n')"

run_test "R: verify pattern succeeds when result matches" \
    "$(printf 'a\nhello\n.\nR/hello/hi/~^hi~\n.p\nQ\n')" \
    "$(printf 'hi\n')"

run_test "R: verify pattern fails when result does not match" \
    "$(printf 'a\nhello\n.\nR/hello/hi/~^xyz~\n.p\nQ\n')" \
    "?"

# --- -L flag (literal mode for s command) ---

run_test "-L: s with literal . does not match any char (error for no match)" \
    "$(printf 'a\nhello\n.\ns/.l/HI/\np\nQ\n')" \
    "?" \
    "-L"

run_test "-L: s without -L, . matches any char" \
    "$(printf 'a\nhello\n.\ns/.l/HI/\np\nQ\n')" \
    "$(printf 'hHIlo\n')" \
    ""

run_test "-L: s with literal * matches literal asterisk" \
    "$(printf 'a\nab*c\n.\ns/b*/XX/\np\nQ\n')" \
    "$(printf 'aXXc\n')" \
    "-L"

run_test "-L: s ignores regex metacharacters" \
    "$(printf 'a\n[a-z]+.txt\n.\ns/\[a-z]+/GLOB/\np\nQ\n')" \
    "$(printf 'GLOB.txt\n')" \
    "-L"

# The literal search [a-z]+ matches the literal text "[a-z]+" in the line.

# --- -C flag (auto-context) ---

# After a\none\ntwo\nthree\nfour\nfive\n.\n3d\nQ:
# Buffer: one two three four five. After a, dot=5.
# 3d: delete line 3 (three). Buffer: one two four five. dot=2.
# -C1 prints context around dot=2: lines 1-3: one two four.
# But auto-context also fires after 'a' command (dot=5, context=4,5), printing four five.
# Then OK tokens... Let me just test with -A to get predictable output.
run_test "-C: auto-context after mutation shows surrounding lines with -A" \
    "$(printf 'a\none\ntwo\nthree\nfour\nfive\n.\n3d\nQ\n')" \
    "$(printf 'four\nfive\nOK 5\ntwo\nfour\nfive\nOK 4\n')" \
    "-AC1"

# --- combined features ---

run_test "-L combined with =1 assertion" \
    "$(printf 'a\nhello world\n.\ns/world/earth/=1\n.p\nQ\n')" \
    "$(printf 'hello earth\n')" \
    "-L"

report
