#!/bin/sh
# t13_shell_escape.sh: test ! (shell escape) command
_current_file="t13_shell_escape"
. "$(dirname "$0")/../harness.sh"

# Basic shell command execution
run_test "shell escape executes command and shows output" \
    "$(printf 'a\nfoo\n.\n!echo hello\nQ\n')" \
    "hello"

# Shell escape does not alter buffer
run_test "shell escape does not modify buffer" \
    "$(printf 'a\nfoo\n.\n!echo ignored\n,p\nQ\n')" \
    "$(printf 'ignored\nfoo')"

# Shell escape with exit code check (clean run = 0)
run_test_exit "shell escape successful run exits 0" \
    "$(printf 'a\nfoo\n.\n!true\nQ\n')" \
    "0"

report
