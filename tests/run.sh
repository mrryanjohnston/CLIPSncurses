#!/bin/sh
# Runs the CLIPSncurses test suite.
#
# Two parts, for two different reasons.
#
#   tests/test.bat        one process, every suite batched into it, one
#                         assertion counter.  This is the suite proper.
#
#   examples/*.bat        every example, driven to its own exit by the keys
#                         in the .keys file beside it.  The examples are
#                         documentation, and this is what keeps them from
#                         quietly becoming fiction.
#
# ncurses draws on standard output and reads keys from standard input, so
# neither is free for the usual purposes.  This script arranges both:
#
#   - Standard output is sent to a file under tests/tmp.  It is the screen,
#     escape sequences and all, and nothing below reads it.  The suite writes
#     its report to standard error instead, which is also where the wrappers
#     report a refused call.
#
#   - Standard input is a fixed sequence of key bytes written by this script,
#     which the input suite reads back through ncurses-getch.  Once those
#     are consumed getch answers -1, so the suite never blocks on a keyboard.
#
#   - The terminal is pinned: TERM=xterm, 24 lines by 80 columns, C locale.
#     ncurses takes the size from the environment when it cannot ask a tty,
#     and takes the key sequences and line-drawing characters from the
#     terminfo entry, so this is what makes the assertions the same on every
#     machine.  An xterm entry ships with every ncurses.
#
# Usage:
#   ./tests/run.sh                     the whole thing
#   ./tests/run.sh suite               only tests/test.bat
#   ./tests/run.sh examples            only the examples
#   CLIPS=/path/to/clips ./tests/run.sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root" || exit 1

CLIPS=${CLIPS:-./vendor/clips/clips}
what=${1:-all}

if [ ! -x "$CLIPS" ]; then
    echo "no CLIPSncurses binary at $CLIPS -- run 'make' first," >&2
    echo "or point at one with CLIPS=/path/to/clips" >&2
    exit 1
fi

export TERM=xterm
export LINES=24
export COLUMNS=80
export LC_ALL=C

# The bytes the input suite reads.  Kept in one place so that the suite and
# this script cannot disagree about them; tests/input-test-suite.bat says
# what each one is expected to become.
keys='a\033OA\033OB\033OC\n'

# A CLIPS that runs out of rules drops into its command loop, and at end of
# file on standard input that loop spins rather than exiting.  An example
# that never reaches (exit) would hang this script, so each one runs under a
# time limit where the system has one.
if command -v timeout >/dev/null 2>&1; then
    limit='timeout 60'
else
    limit=
fi

# Written by the suite, the examples and this script; removed at both ends
# so a run that died half way cannot seed the next one.
rm -rf tests/tmp
mkdir -p tests/tmp

failures=0

# ----------------------------------------------------------------------
# the in-process suite
# ----------------------------------------------------------------------

if [ "$what" = all ] || [ "$what" = suite ]; then
    printf "$keys" | $limit "$CLIPS" -f2 tests/test.bat > tests/tmp/suite.screen
    status=$?
    if [ "$status" -ne 0 ]; then
        failures=$((failures + 1))
        echo
        echo "FAILED: tests/test.bat (exit $status)"
    fi
fi

# ----------------------------------------------------------------------
# the examples
#
# Each one is a program that waits on the keyboard, so each is fed the keys
# in the .keys file beside it -- a printf format, so an arrow key can be
# spelled \033OB -- and has to reach its own (exit) on them.  What it drew
# on the way is not checked: the screen is escape sequences, and what they
# say depends on how ncurses chose to update it.  Three things are:
#
#   - it exited, with status 0, before the time limit;
#   - it wrote nothing to standard error, which is where every wrapper in
#     this library reports a refused call;
#   - the keys were enough.  An example that outlives its keys reads -1
#     from getch forever or drops into the CLIPS command loop, and either
#     way the limit is what ends it.
# ----------------------------------------------------------------------

check_example() {
    example=$1
    keyfile=${example%.bat}.keys
    name=$(basename "$example" .bat)
    screen=tests/tmp/$name.screen
    err=tests/tmp/$name.err

    if [ ! -f "$keyfile" ]; then
        echo
        echo "FAILED: $example has no $keyfile beside it"
        failures=$((failures + 1))
        return
    fi

    printf "$(cat "$keyfile")" | $limit "$CLIPS" -f2 "$example" >"$screen" 2>"$err"
    status=$?

    if [ "$status" -eq 124 ] && [ -n "$limit" ]; then
        echo
        echo "FAILED: $example did not exit on the keys in $keyfile"
        failures=$((failures + 1))
        return
    fi

    if [ "$status" -ne 0 ]; then
        echo
        echo "FAILED: $example exited $status"
        sed -n '1,20p' "$err"
        failures=$((failures + 1))
        return
    fi

    if [ -s "$err" ]; then
        echo
        echo "FAILED: $example wrote to stderr"
        sed -n '1,20p' "$err"
        failures=$((failures + 1))
        return
    fi

    printf '.' >&2
}

if [ "$what" = all ] || [ "$what" = examples ]; then
    echo >&2
    printf 'examples ' >&2
    for example in examples/*.bat; do
        [ -f "$example" ] || continue
        check_example "$example"
    done
    echo >&2
fi

rm -rf tests/tmp

if [ "$failures" -gt 0 ]; then
    echo "FAILED"
    exit 1
fi

echo "PASSED"
