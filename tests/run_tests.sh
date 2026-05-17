#!/bin/sh
# run_tests.sh: master test runner for oed.
# Must be run from the project root: sh tests/run_tests.sh

# Locate project root (one level above this script's directory)
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$TESTS_DIR/.." && pwd)"
cd "$ROOT"

export OED="./oed"

total_pass=0
total_fail=0

run_sh_file() {
    _file="$1"
    # Run the test file; capture stdout+stderr; do not fail the runner on non-zero exit
    _out=$(sh "$_file" 2>&1) || true
    printf '%s\n' "$_out"
    _p=$(printf '%s\n' "$_out" | grep -c '^PASS' 2>/dev/null) || _p=0
    _f=$(printf '%s\n' "$_out" | grep -c '^FAIL' 2>/dev/null) || _f=0
    total_pass=$((total_pass + _p))
    total_fail=$((total_fail + _f))
}

echo "=== Shell integration tests ==="
for t in "$TESTS_DIR"/sh/t*.sh; do
    run_sh_file "$t"
done

echo ""
echo "=== C unit tests ==="
for bin in "$TESTS_DIR"/unit/test_*; do
    [ -x "$bin" ] || continue
    # Skip .o files and .c source files
    case "$bin" in *.o|*.c) continue ;; esac
    _out=$("$bin" 2>&1) || true
    printf '%s\n' "$_out"
    _p=$(printf '%s\n' "$_out" | grep -c '^PASS' 2>/dev/null) || _p=0
    _f=$(printf '%s\n' "$_out" | grep -c '^FAIL' 2>/dev/null) || _f=0
    total_pass=$((total_pass + _p))
    total_fail=$((total_fail + _f))
done

echo ""
printf -- '=== Summary: %d passed, %d failed ===\n' "$total_pass" "$total_fail"

[ "$total_fail" -eq 0 ]
