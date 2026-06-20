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

# ================================================================
# --- R command (replace literal) ---
# ================================================================

# -- delimiter edge cases --

run_test "R: alternate delimiter pipe" \
    "$(printf 'a\nhello world\n.\nR|world|earth|\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: alternate delimiter colon" \
    "$(printf 'a\nhello world\n.\nR:world:earth:\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: alternate delimiter semicolon" \
    "$(printf 'a\nhello world\n.\nR;world;earth;\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: alternate delimiter comma" \
    "$(printf 'a\nhello world\n.\nR,world,earth,\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: alternate delimiter tilde" \
    "$(printf 'a\nhello world\n.\nR~world~earth~\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: space after R is rejected" \
    "$(printf 'a\nhello\n.\nR /foo/bar/\n.p\nQ\n')" \
    "?"

run_test "R: newline after R is rejected" \
    "$(printf 'a\nhello\n.\nR\n.p\nQ\n')" \
    "?"

run_test "R: missing closing delim ends at newline" \
    "$(printf 'a\nhello world\n.\nR/world/earth\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

# -- basic literal matching --

run_test "R: basic literal replacement" \
    "$(printf 'a\nhello world\n.\nR/world/earth/\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: literal . does not match any character (error because no match)" \
    "$(printf 'a\nhello\n.\nR/.l/HI/\n.p\nQ\n')" \
    "?"

run_test "R: literal * matches literal asterisk" \
    "$(printf 'a\nfoo*bar\n.\nR/o*/XX/\n.p\nQ\n')" \
    "$(printf 'foXXbar\n')"

run_test "R: literal ^ and $ are matched as ordinary chars" \
    "$(printf 'a\n^hello$\n.\nR/^hello$/MATCH/\n.p\nQ\n')" \
    "$(printf 'MATCH\n')"

run_test "R: literal regex metacharacters are not interpreted" \
    "$(printf 'a\n[a-z]+.txt\n.\nR/[a-z]+.txt/GLOB/\n.p\nQ\n')" \
    "$(printf 'GLOB\n')"

run_test "R: slash in replacement text works" \
    "$(printf 'a\nhello\n.\nR/hello/foo\\/bar/\n.p\nQ\n')" \
    "$(printf 'foo/bar\n')"

# -- zero-length search --

run_test "R: zero-length search prepends replacement" \
    "$(printf 'a\nhello\n.\nR//PREFIX/\n.p\nQ\n')" \
    "$(printf 'PREFIXhello\n')"

run_test "R: zero-length search with g flag prepends at every position" \
    "$(printf 'a\nab\n.\nR//X/g\n.p\nQ\n')" \
    "$(printf 'XaXb\n')"

# -- escape sequences in search text --

run_test "R: \\t in search matches literal tab" \
    "$(printf 'a\nHELLO\tWORLD\n.\nR/HELLO\\tWORLD/TAB/\n.p\nQ\n')" \
    "$(printf 'TAB\n')"

run_test "R: \\n in search enacts multi-line matching" \
    "$(printf 'a\nhello\nworld\n.\n1,2R/hello\\nworld/XX/\n,p\nQ\n')" \
    "$(printf 'XX\n')"

run_test "R: double backslash in search matches literal backslash" \
    "$(printf 'a\na\\b\n.\nR/a\\\\b/XX/\n.p\nQ\n')" \
    "$(printf 'XX\n')"

# -- escape sequences in replacement text --

run_test "R: \\n in replacement splits the line" \
    "$(printf 'a\nfoo:bar\n.\nR/:/\\n/\n,p\nQ\n')" \
    "$(printf 'foo\nbar\n')"

run_test "R: \\t in replacement inserts literal tab" \
    "$(printf 'a\nfooXbar\n.\nR/X/\\t/\n.p\nQ\n')" \
    "$(printf 'foo\tbar\n')"

run_test "R: \\n then content in replacement" \
    "$(printf 'a\nfoo\n.\nR/foo/\\nbar/\n,p\nQ\n')" \
    "$(printf '\nbar\n')"

# -- & and \1-\9 are literal in R replacement --

run_test "R: & treated literally (no match insertion)" \
    "$(printf 'a\nhello\n.\nR/hello/&_world/\n.p\nQ\n')" \
    "$(printf '&_world\n')"

run_test "R: \\& emits literal & (backslash-stripped)" \
    "$(printf 'a\nhello\n.\nR/hello/\\&/\n.p\nQ\n')" \
    "$(printf '&\n')"

run_test "R: \\\\& emits literal \\\\&" \
    "$(printf 'a\nhello\n.\nR/hello/\\\\\\\\&/\n.p\nQ\n')" \
    "$(printf '\\\&\n')"

# -- \\n and \\t still work as escapes in R --

run_test "R: \\n in replacement splits line" \
    "$(printf 'a\nhello\n.\nR/hello/\\nworld/\n,p\nQ\n')" \
    "$(printf '\nworld\n')"

run_test "R: \\t in replacement inserts tab" \
    "$(printf 'a\nhello\n.\nR/hello/\\tWORLD/\n.p\nQ\n')" \
    "$(printf '\tWORLD\n')"

# -- empty replacement --

run_test "R: empty replacement deletes matched text" \
    "$(printf 'a\nhello world\n.\nR/hello //\n.p\nQ\n')" \
    "$(printf 'world\n')"

# -- g flag and nth occurrence --

run_test "R: g flag replaces all occurrences" \
    "$(printf 'a\naa bb aa\n.\nR/aa/XX/g\n.p\nQ\n')" \
    "$(printf 'XX bb XX\n')"

run_test "R: 2nd occurrence replaces only the second match" \
    "$(printf 'a\naa aa aa\n.\nR/aa/XX/2\n.p\nQ\n')" \
    "$(printf 'aa XX aa\n')"

run_test "R: 3rd occurrence replaces only the third match" \
    "$(printf 'a\naa aa aa\n.\nR/aa/XX/3\n.p\nQ\n')" \
    "$(printf 'aa aa XX\n')"

run_test "R: g flag no-match returns error" \
    "$(printf 'a\nhello\n.\nR/xyz/XX/g\n.p\nQ\n')" \
    "?"

# -- display suffix flags (p, l, n) --

run_test "R: p flag prints substituted line" \
    "$(printf 'a\nhello world\n.\nR/world/earth/p\n.p\nQ\n')" \
    "$(printf 'hello earth\nhello earth\n')"

run_test "R: l flag prints substituted line with escapes" \
    "$(printf 'a\nhello\tworld\n.\nR/\\t/ /l\n.p\nQ\n')" \
    "$(printf 'hello world\044\nhello world\n')"

run_test "R: n flag prints substituted line with line number" \
    "$(printf 'a\nhello\n.\nR/hello/hi/n\n.p\nQ\n')" \
    "$(printf '1\thi\nhi\n')"

run_test "R: g flag with p flag shows result once" \
    "$(printf 'a\naa bb aa\n.\nR/aa/XX/gp\n.p\nQ\n')" \
    "$(printf 'XX bb XX\nXX bb XX\n')"

# -- =N exact-count assertion --

run_test "R: =1 exact count assertion succeeds" \
    "$(printf 'a\nhello world\n.\nR/world/earth/=1\n.p\nQ\n')" \
    "$(printf 'hello earth\n')"

run_test "R: =0 exact count assertion fails when match exists" \
    "$(printf 'a\nhello world\n.\nR/world/earth/=0\n.p\nQ\n')" \
    "?"

run_test "R: =2 exact count assertion fails with rollback when only one line matched" \
    "$(printf 'a\nfoo\n.\nR/foo/bar/=2\n.p\nQ\n')" \
    "$(printf '?\nfoo')" \
    "-l"

run_test "R: =2 exact count assertion succeeds when two lines match" \
    "$(printf 'a\nfoo\nfoo\n.\n1,2R/foo/bar/=2\n,p\nQ\n')" \
    "$(printf 'bar\nbar\n')"

# -- ! all-or-nothing assertion --

run_test "R: ! all-or-nothing succeeds when all lines match" \
    "$(printf 'a\nhello\nworld\n.\n1,2R/o/O/!\np\nQ\n')" \
    "$(printf 'wOrld\n')"

run_test "R: ! all-or-nothing fails and rolls back when not all lines match" \
    "$(printf 'a\nfoo\nbar\nbaz\n.\n1,3R/foo/XX/!\n,p\nQ\n')" \
    "$(printf '?\nfoo\nbar\nbaz')" \
    "-l"

run_test "R: ! all-or-nothing with =1 exact count on single line" \
    "$(printf 'a\nfoo\n.\nR/foo/bar/!=1\n.p\nQ\n')" \
    "$(printf 'bar\n')"

run_test "R: ! all-or-nothing with =2 exact count fails on mismatch" \
    "$(printf 'a\nfoo\n.\nR/foo/bar/!=2\n.p\nQ\n')" \
    "$(printf '?\nfoo')" \
    "-l"

# -- D dry-run --

run_test "R: D dry-run prints without modifying buffer" \
    "$(printf 'a\nhello world\n.\nR/world/earth/D\n.p\nQ\n')" \
    "$(printf 'hello earth\nhello world\n')"

run_test "R: D dry-run with =1 exact count succeeds" \
    "$(printf 'a\nhello\n.\nR/hello/hi/D=1\n.p\nQ\n')" \
    "$(printf 'hi\nhello\n')"

run_test "R: D dry-run with =0 prints result then errors" \
    "$(printf 'a\nhello\n.\nR/hello/hi/D=0\n.p\nQ\n')" \
    "$(printf 'hi\n?')"

# -- ~re~ result verify --

run_test "R: verify pattern succeeds when result matches" \
    "$(printf 'a\nhello\n.\nR/hello/hi/~^hi~\n.p\nQ\n')" \
    "$(printf 'hi\n')"

run_test "R: verify pattern fails when result does not match" \
    "$(printf 'a\nhello\n.\nR/hello/hi/~^xxx~\n.p\nQ\n')" \
    "?"

run_test "R: D dry-run with verify pattern succeeds" \
    "$(printf 'a\nhello\n.\nR/hello/hi/D~^hi~\n.p\nQ\n')" \
    "$(printf 'hi\nhello\n')"

run_test "R: D dry-run with verify pattern fails on mismatch" \
    "$(printf 'a\nhello\n.\nR/hello/hi/D~^xxx~\n.p\nQ\n')" \
    "?"

# -- combined flag tests --

run_test "R: p flag with =1 exact count combined" \
    "$(printf 'a\nhello\n.\nR/hello/hi/p=1\n.p\nQ\n')" \
    "$(printf 'hi\nhi\n')"

# -- address range behavior --

run_test "R: explicit range replaces on multiple lines" \
    "$(printf 'a\nfoo\nfoo\nbar\n.\n1,3R/foo/XX/\n,p\nQ\n')" \
    "$(printf 'XX\nXX\nbar\n')"

run_test "R: 1,$ range replaces in whole buffer" \
    "$(printf 'a\nfoo\nfoo\n.\n1,\044R/foo/XX/\n,p\nQ\n')" \
    "$(printf 'XX\nXX\n')"

run_test "R: range with no match returns error" \
    "$(printf 'a\nhello\nworld\n.\n1,2R/xyz/XX/\n,p\nQ\n')" \
    "$(printf '?\nhello\nworld')" \
    "-l"

# bare address 1 prints line 1 and sets dot; then R operates on that line
run_test "R: default address (dot) operates on current line" \
    "$(printf 'a\nfoo foo\nbar bar\n.\n1\nR/oo/XX/\n,p\nQ\n')" \
    "$(printf 'foo foo\nfXX foo\nbar bar\n')"

run_test "R: default address errors on no match" \
    "$(printf 'a\nfoo\nbar\n.\nR/zzz/XX/\n.p\nQ\n')" \
    "?"

# -- OK token with -A flag --

run_test "R: -A prints OK token with 1subs" \
    "$(printf 'a\nhello\n.\nR/hello/hi/\nQ\n')" \
    "$(printf 'OK 1\nOK 1 1subs')" \
    "-A"

run_test "R: -A prints OK token with 2subs" \
    "$(printf 'a\nfoo\nfoo\n.\n1,2R/foo/bar/\nQ\n')" \
    "$(printf 'OK 2\nOK 2 2subs')" \
    "-A"

# a command succeeds (OK 1), then R with no match errors (?)
run_test "R: -A with no match prints OK from a then ? from R" \
    "$(printf 'a\nhello\n.\nR/xyz/XX/\nQ\n')" \
    "$(printf 'OK 1\n?')" \
    "-Al"

# -- inside global commands --

run_test "R: inside global g works" \
    "$(printf 'a\nhello world\nfoo bar\n.\ng/foo/R/foo/bar/\n,p\nQ\n')" \
    "$(printf 'hello world\nbar bar\n')"

run_test "R: inside global v works" \
    "$(printf 'a\nhello world\nfoo bar\n.\nv/hello/R/foo/bar/\n,p\nQ\n')" \
    "$(printf 'hello world\nbar bar\n')"

# -- undo --

run_test "R: undo after R restores original content" \
    "$(printf 'a\nhello\n.\nR/hello/hi/\nu\n.p\nQ\n')" \
    "$(printf 'hello\n')"

# -- read-only mode --

# -R -l rejects a (read-only), then hello/. are bad cmds,
# then R is rejected, then .p has no buffer — all produce ?
run_test "R: read-only mode rejects R command" \
    "$(printf 'a\nhello\n.\nR/hello/hi/\n.p\nQ\n')" \
    "$(printf '?\n?\n?\n?\n?\n')" \
    "-Rl"

# -- empty buffer R errors --

run_test "R: empty buffer R returns error" \
    "$(printf 'R/a/b/\nQ\n')" \
    "?"

# ================================================================
# --- -L flag (literal mode for s command) ---
# ================================================================

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

# ================================================================
# --- -C flag (auto-context) ---
# ================================================================

run_test "-C: auto-context after mutation shows surrounding lines with -A" \
    "$(printf 'a\none\ntwo\nthree\nfour\nfive\n.\n3d\nQ\n')" \
    "$(printf 'four\nfive\nOK 5\ntwo\nfour\nfive\nOK 4\n')" \
    "-AC1"

# ================================================================
# --- combined features ---
# ================================================================

run_test "-L combined with =1 assertion" \
    "$(printf 'a\nhello world\n.\ns/world/earth/=1\n.p\nQ\n')" \
    "$(printf 'hello earth\n')" \
    "-L"

report
