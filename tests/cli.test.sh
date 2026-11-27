# shellcheck shell=bash
# shellcheck disable=SC2016  # fixtures are written with single quotes on purpose
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

before_each() { make_workspace; }
after_each() { remove_workspace; }

# @test --version prints the constant version
test_version() {
  run_shest --version
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_match '^shest [0-9]+\.[0-9]+\.[0-9]+$'
}

# @test --help lists the options and exits 0
test_help() {
  run_shest --help
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "--coverage"
  expect "$OUTPUT" to_contain "--parallel"
  expect "$OUTPUT" to_contain "# @test.todo"
}

# @test an unknown option fails with a message
test_unknown_option() {
  run_shest --nope
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "unknown option: --nope"
}

# @test no test files found fails
test_no_files() {
  run_shest
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "no test files found"
}

# @test --config with a missing file fails
test_missing_config() {
  run_shest --config nope.sh
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "config file not found: nope.sh"
}

# @test --init creates shest.config.sh and refuses to overwrite it
test_init() {
  run_shest --init
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "Created shest.config.sh"
  expect "$(cat shest.config.sh)" to_contain "COVERAGE_THRESHOLD"

  run_shest --init
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "already exists"
}

# @test a generated config file is valid and changes nothing
test_init_config_is_inert() {
  run_shest --init
  add_test a.test.sh test "passes" 'expect 1 to_be 1'
  run_shest a.test.sh
  expect "$STATUS" to_be 0
}

# @test invalid numeric options are rejected
test_invalid_options() {
  run_shest --parallel 0
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "PARALLEL must be a positive integer"

  run_shest --timeout abc
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "TEST_TIMEOUT must be a number"

  run_shest --coverage-reporters html
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "unknown coverage reporter: html"
}
