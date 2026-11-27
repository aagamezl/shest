# shellcheck shell=bash
# shellcheck disable=SC2016  # fixtures are written with single quotes on purpose
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

before_each() { make_workspace; }
after_each() { remove_workspace; }

# @test a passing file exits 0 and reports the totals
test_passing() {
  add_test a.test.sh test "one" 'expect 1 to_be 1'
  add_test a.test.sh test "two" 'expect 2 to_be 2'
  run_shest a.test.sh
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "✓ one"
  expect "$OUTPUT" to_contain "Test Files:  1 passed, 1 total"
  expect "$OUTPUT" to_contain "Tests:       2 passed, 2 total"
}

# @test a failing test exits 1 and shows the matcher details
test_failing() {
  make_mixed_file a.test.sh
  run_shest a.test.sh
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "✗ fails"
  expect "$OUTPUT" to_contain "Expected: 2"
  expect "$OUTPUT" to_contain "Received: 1"
  expect "$OUTPUT" to_contain "Test Files:  1 failed, 0 passed, 1 total"
  expect "$OUTPUT" to_contain "Tests:       1 failed, 1 passed, 2 total"
}

# @test .skip, .todo and .only are counted and not run
test_modes() {
  add_test a.test.sh test.skip "skipped" 'expect 1 to_be 2'
  add_todo a.test.sh "planned"
  add_test a.test.sh test "plain" 'expect 1 to_be 2'
  add_test a.test.sh test.only "focused" 'expect 1 to_be 1'
  run_shest a.test.sh
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "○ skipped (skipped)"
  expect "$OUTPUT" to_contain "✎ planned (todo)"
  expect "$OUTPUT" to_contain "○ plain (skipped)"
  expect "$OUTPUT" to_contain "✓ focused"
  expect "$OUTPUT" to_contain "Tests:       2 skipped, 1 todo, 1 passed, 4 total"
}

# @test --filter runs only tests whose name matches
test_filter() {
  add_test a.test.sh test "adds numbers" 'expect 1 to_be 1'
  add_test a.test.sh test "divides numbers" 'expect 1 to_be 2'
  run_shest a.test.sh --filter 'adds'
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "✓ adds numbers"
  expect "$OUTPUT" to_contain "○ divides numbers (skipped)"
}

# @test hooks run in order and after_each runs even when a test fails
test_hooks() {
  printf 'log() { echo "$1" >>hooks.log; }\nbefore_all() { log before_all; }\nafter_all() { log after_all; }\nbefore_each() { log before_each; }\nafter_each() { log after_each; }\n' >a.test.sh
  add_test a.test.sh test "first" 'log first'
  add_test a.test.sh test "second" 'log second; expect 1 to_be 2'
  run_shest a.test.sh
  expect "$STATUS" to_be 1
  expect "$(tr '\n' ' ' <hooks.log)" to_be "before_all before_each first after_each before_each second after_each after_all "
}

# @test a decorator without a function is a discovery error
test_decorator_without_function() {
  printf '# @test lonely\n\necho not a function\n' >a.test.sh
  run_shest a.test.sh
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "'# @test' must be followed by a function declaration"
}

# @test a test file that cannot be sourced fails the file
test_broken_file() {
  printf 'this is (not valid\n' >a.test.sh
  run_shest a.test.sh
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "Test Files:  1 failed"
}

# @test a directory runs every *.test.sh below it
test_directory() {
  mkdir -p sub/deep
  add_test sub/a.test.sh test "a" 'expect 1 to_be 1'
  add_test sub/deep/b.test.sh test "b" 'expect 1 to_be 1'
  : >sub/helper.sh
  run_shest sub
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "Test Files:  2 passed, 2 total"
}

# @test ** globs match any depth
test_recursive_glob() {
  mkdir -p t/x/y
  add_test t/x/y/a.test.sh test "deep" 'expect 1 to_be 1'
  add_test t/b.test.sh test "shallow" 'expect 1 to_be 1'
  run_shest --path 't/**/*.test.sh'
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "Test Files:  2 passed, 2 total"
}

# @test --bail stops after the first failing file
test_bail() {
  make_mixed_file a.test.sh
  add_test b.test.sh test "never runs" 'expect 1 to_be 1'
  run_shest a.test.sh b.test.sh --bail
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "Bailed after the first failing file: 1 file(s) not run"
  expect "$OUTPUT" not to_contain "never runs"
}

# @test each file runs in its own process
test_isolation() {
  printf 'LEAK=yes\n' >a.test.sh
  add_test a.test.sh test "sets a variable" 'expect "$LEAK" to_be yes'
  add_test b.test.sh test "does not see it" 'expect "${LEAK:-unset}" to_be unset'
  run_shest a.test.sh b.test.sh
  expect "$STATUS" to_be 0
}

# @test --timing shows the duration of each test
test_timing() {
  add_test a.test.sh test "quick" 'expect 1 to_be 1'
  run_shest a.test.sh --timing
  expect "$OUTPUT" to_match '✓ quick \([0-9]+ ms\)'
}

# @test the summary is the last thing printed, after coverage
test_summary_is_last() {
  make_coverage_project
  run_shest lib.test.sh --coverage
  expect "$(printf '%s\n' "$OUTPUT" | tail -n 1)" to_start_with "Time:"
}
