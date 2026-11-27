# shellcheck shell=bash
# shellcheck disable=SC2016  # fixtures are written with single quotes on purpose
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

before_each() { make_workspace; }
after_each() { remove_workspace; }

# @test shest.config.sh is picked up from the current directory
test_default_config() {
  mkdir tests
  add_test tests/a.test.sh test "inside" 'expect 1 to_be 1'
  add_test other.test.sh test "outside" 'expect 1 to_be 1'
  printf 'TEST_MATCH=("tests")\n' >shest.config.sh
  run_shest
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "inside"
  expect "$OUTPUT" not to_contain "outside"
}

# @test --config uses another file
test_config_flag() {
  add_test a.test.sh test "runs" 'expect 1 to_be 1'
  printf 'TEST_MATCH=("a.test.sh")\nTIMING=true\n' >ci.sh
  run_shest --config ci.sh
  expect "$OUTPUT" to_match '✓ runs \([0-9]+ ms\)'
}

# @test command-line options override the config file
test_cli_overrides() {
  make_mixed_file a.test.sh
  printf 'COVERAGE_THRESHOLD=100\nTEST_MATCH=("a.test.sh")\n' >shest.config.sh
  run_shest --coverage-threshold 0 --filter 'passes'
  expect "$STATUS" to_be 0
}

# @test TEST_PATH_IGNORE_PATTERNS skips files whose path contains a pattern
test_ignore_paths() {
  mkdir -p build keep
  add_test build/a.test.sh test "ignored" 'expect 1 to_be 2'
  add_test keep/b.test.sh test "kept" 'expect 1 to_be 1'
  printf 'TEST_PATH_IGNORE_PATTERNS=("/build/")\n' >shest.config.sh
  run_shest .
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "Test Files:  1 passed, 1 total"
}

# @test ignore patterns are literal substrings, not globs
test_ignore_is_literal() {
  add_test a.test.sh test "kept" 'expect 1 to_be 1'
  printf 'TEST_PATH_IGNORE_PATTERNS=("*.test.sh")\n' >shest.config.sh
  run_shest a.test.sh
  expect "$OUTPUT" to_contain "kept"
}

# @test invalid config values stop shest with a message
test_invalid_values() {
  printf 'REPORTER=xml\n' >shest.config.sh
  run_shest
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "unknown REPORTER: xml"

  printf 'COVERAGE_THRESHOLD=80.5\n' >shest.config.sh
  run_shest
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "COVERAGE_THRESHOLD must be an integer"

  printf 'PARALLEL=0\n' >shest.config.sh
  run_shest
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "PARALLEL must be a positive integer"
}

# @test a threshold in the config turns coverage on
test_threshold_enables_coverage() {
  printf 'double() { echo 2; }\n' >lib.sh
  printf 'source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"\n' >a.test.sh
  add_test a.test.sh test "uses lib" 'double'
  printf 'COVERAGE_THRESHOLD=10\n' >shest.config.sh
  run_shest a.test.sh
  expect "$OUTPUT" to_contain "Coverage:"
}
