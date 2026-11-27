# shellcheck shell=bash
# shellcheck disable=SC2016  # fixtures are written with single quotes on purpose
#
# Helpers for the tests that run shest against throwaway projects.
#
# Fixture tests are written with printf instead of heredocs on purpose: shest
# scans this file for "# @test" lines, and a decorator inside a heredoc would
# be read as one of ours.

SHEST_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/shest"
FIXTURE_COUNTER=0

# Create a temporary project and move into it (call from before_each).
make_workspace() {
  WORKSPACE="$(mktemp -d)"
  cd "$WORKSPACE" || return 1
}

remove_workspace() {
  cd / && rm -rf "$WORKSPACE"
}

# Run shest in the current directory. Sets OUTPUT (stdout and stderr) and STATUS.
run_shest() {
  STATUS=0
  # A clean environment: nothing from the shest that runs this test may leak in.
  OUTPUT="$(env -u SHEST_FORCE_COLOR -u SHEST_TIMING -u SHEST_TEST_TIMEOUT -u SHEST_EVENTS_FILE -u SHEST_COVERAGE_FILE -u SHEST_RESULTS_FILE \
    NO_COLOR=1 bash "$SHEST_BIN" "$@" 2>&1)" || STATUS=$?
}

# Append a test to a fixture file: add_test <file> <decorator> <name> <body>
#   add_test a.test.sh test "adds" 'expect 1 to_be 1'
#   add_test a.test.sh test.skip "later" 'expect 1 to_be 2'
add_test() {
  local file="$1" decorator="$2" name="$3" body="$4"

  FIXTURE_COUNTER=$((FIXTURE_COUNTER + 1))
  printf '# @%s %s\nfixture_%s() {\n  %s\n}\n\n' "$decorator" "$name" "$FIXTURE_COUNTER" "$body" >>"$file"
}

# A .todo needs no function: add_todo <file> <name>
add_todo() {
  printf '# @test.todo %s\n\n' "$2" >>"$1"
}

# A fixture file with one passing and one failing test.
make_mixed_file() {
  : >"$1"
  add_test "$1" test "passes" 'expect 1 to_be 1'
  add_test "$1" test "fails" 'expect 1 to_be 2'
}

# A small library plus a test that only covers part of it.
make_coverage_project() {
  printf 'double() {\n  echo $(($1 * 2))\n}\n\ntriple() {\n  echo $(($1 * 3))\n}\n' >lib.sh
  printf 'source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"\n\n' >lib.test.sh
  add_test lib.test.sh test "doubles" 'expect "$(double 2)" to_be 4'
}
