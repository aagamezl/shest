# shellcheck shell=bash
# shellcheck disable=SC2016  # fixtures are written with single quotes on purpose
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

before_each() {
  make_workspace
  make_coverage_project
}
after_each() { remove_workspace; }

# @test --coverage prints a table with the uncovered lines
test_table() {
  run_shest lib.test.sh --coverage
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "┌"
  expect "$OUTPUT" to_match '│ lib\.sh +│ +50\.00 │ +1/2 │ 6 +│'
  expect "$OUTPUT" to_contain "Coverage: 50.00% (1/2 lines)"
}

# @test test files are never listed in the coverage report
test_excludes_tests() {
  run_shest lib.test.sh --coverage
  expect "$OUTPUT" not to_match '│ lib\.test\.sh'
}

# @test a threshold above the coverage fails the run
test_threshold_fails() {
  run_shest lib.test.sh --coverage-threshold 80
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "Coverage 50.00% is below the threshold of 80%"
}

# @test a threshold at or below the coverage passes
test_threshold_passes() {
  run_shest lib.test.sh --coverage-threshold 50
  expect "$STATUS" to_be 0
}

# @test the threshold is checked exactly, not rounded
test_threshold_is_exact() {
  add_test lib.test.sh test "triples" 'expect "$(triple 2)" to_be 6'
  run_shest lib.test.sh --coverage-threshold 100
  expect "$STATUS" to_be 0
}

# @test COVERAGE_PATH_IGNORE_PATTERNS removes files from the report
test_ignore_pattern() {
  printf 'COVERAGE_PATH_IGNORE_PATTERNS=("lib.sh")\n' >shest.config.sh
  run_shest lib.test.sh --coverage
  expect "$OUTPUT" to_contain "no source files were executed"
}

# @test --coverage-reporters writes lcov and cobertura files
test_file_reporters() {
  run_shest lib.test.sh --coverage-reporters text,lcov,cobertura --coverage-directory out
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "lcov report written to out/lcov.info"
  expect "$(cat out/lcov.info)" to_contain "SF:${PWD}/lib.sh"
  expect "$(cat out/lcov.info)" to_contain "DA:6,0"
  expect "$(cat out/lcov.info)" to_contain "LH:1"
  expect "$(cat out/cobertura-coverage.xml)" to_contain 'lines-covered="1" lines-valid="2"'
  expect "$(cat out/cobertura-coverage.xml)" to_contain 'filename="lib.sh"'
}

# @test without the text reporter only the percentage is printed
test_no_text_reporter() {
  run_shest lib.test.sh --coverage-reporters lcov
  expect "$OUTPUT" to_contain "Coverage: 50.00% (1/2 lines)"
  expect "$OUTPUT" not to_contain "┌"
}
