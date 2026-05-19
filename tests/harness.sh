# harness.sh: sourced by every shell test file.
# Expects CWD = project root and HED set (or defaults to ./hed).

HED="${HED:-./hed}"
_passes=0
_failures=0
_current_file="${_current_file:-unknown}"

# Temp directory cleaned up at exit
_TDIR=$(mktemp -d /tmp/hed_test_XXXXXX)
trap 'rm -rf "$_TDIR"' EXIT INT TERM

# run_test NAME INPUT EXPECTED [OED_FLAGS]
#   Pipes INPUT into hed (with -s plus any extra FLAGS), compares stdout to EXPECTED.
run_test() {
    _name="$1"
    _input="$2"
    _expected="$3"
    _flags="${4:-}"

    _got=$(printf '%s\n' "$_input" | "$HED" -s $_flags 2>/dev/null)
    if [ "$_got" = "$_expected" ]; then
        _passes=$((_passes + 1))
        printf 'PASS  %s: %s\n' "$_current_file" "$_name"
    else
        _failures=$((_failures + 1))
        printf 'FAIL  %s: %s\n' "$_current_file" "$_name"
        printf '  expected: [%s]\n' "$_expected"
        printf '  got:      [%s]\n' "$_got"
    fi
}

# run_test_exit NAME INPUT EXPECTED_EXIT [OED_FLAGS]
#   Only checks exit code, not output.
run_test_exit() {
    _name="$1"
    _input="$2"
    _expected_exit="$3"
    _flags="${4:-}"

    printf '%s\n' "$_input" | "$HED" -s $_flags >/dev/null 2>&1
    _got_exit=$?
    if [ "$_got_exit" = "$_expected_exit" ]; then
        _passes=$((_passes + 1))
        printf 'PASS  %s: %s\n' "$_current_file" "$_name"
    else
        _failures=$((_failures + 1))
        printf 'FAIL  %s: %s (expected exit %s, got %s)\n' \
            "$_current_file" "$_name" "$_expected_exit" "$_got_exit"
    fi
}

# run_test_file NAME INPUT EXPECTED_FILE_CONTENT FILE_PATH [OED_FLAGS]
#   Runs hed and checks the content of a file it wrote.
run_test_file() {
    _name="$1"
    _input="$2"
    _expected_content="$3"
    _fpath="$4"
    _flags="${5:-}"

    printf '%s\n' "$_input" | "$HED" -s $_flags >/dev/null 2>&1
    if [ -f "$_fpath" ]; then
        _got_content=$(cat "$_fpath")
    else
        _got_content=""
    fi
    if [ "$_got_content" = "$_expected_content" ]; then
        _passes=$((_passes + 1))
        printf 'PASS  %s: %s\n' "$_current_file" "$_name"
    else
        _failures=$((_failures + 1))
        printf 'FAIL  %s: %s (file content mismatch)\n' "$_current_file" "$_name"
        printf '  expected: [%s]\n' "$_expected_content"
        printf '  got:      [%s]\n' "$_got_content"
    fi
}

# report: print summary for this file; return 1 if any failures
report() {
    printf -- '--- %s: %d passed, %d failed\n' "$_current_file" "$_passes" "$_failures"
    [ "$_failures" -eq 0 ]
}
