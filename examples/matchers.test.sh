# shellcheck shell=bash

# Runs a matcher expected to fail and fails the test if it passes.
expect_failure() {
  if expect "$@" >/dev/null; then
    echo "Expected matcher to fail: $*"
    return 1
  fi
}

# @test to_be_greater_than passes for a larger number
test_greater_than_passes() {
  expect 4 to_be_greater_than 3
  expect 3.5 to_be_greater_than 3
}

# @test to_be_greater_than fails for an equal or smaller number
test_greater_than_fails() {
  expect_failure 3 to_be_greater_than 3
  expect_failure 2 to_be_greater_than 3
}

# @test to_be_greater_than_or_equal accepts equal and larger decimals
test_greater_than_or_equal_passes() {
  expect 3.5 to_be_greater_than_or_equal 3.5
  expect 4 to_be_greater_than_or_equal 3.5
  expect_failure 3 to_be_greater_than_or_equal 3.5
}

# @test to_be_less_than passes for a smaller number
test_less_than_passes() {
  expect 4 to_be_less_than 5
  expect_failure 5 to_be_less_than 5
}

# @test to_be_less_than_or_equal accepts equal and smaller decimals
test_less_than_or_equal_passes() {
  expect 4.5 to_be_less_than_or_equal 4.5
  expect 4 to_be_less_than_or_equal 4.5
  expect_failure 5 to_be_less_than_or_equal 4.5
}

# @test to_be_true only accepts true
test_to_be_true() {
  expect true to_be_true
  expect_failure false to_be_true
  expect_failure "" to_be_true
}

# @test to_be_false only accepts false
test_to_be_false() {
  expect false to_be_false
  expect_failure true to_be_false
}

# @test to_match checks a regular expression
test_to_match() {
  expect "Christoph" to_match 'stop'
  expect "Christoph" to_match '^Chr.*ph$'
  expect_failure "Christoph" to_match '^stop'
}

# @test to_contain checks for a substring
test_to_contain() {
  expect "milk and bread" to_contain "milk"
  expect_failure "milk and bread" to_contain "eggs"
}

# @test to_contain_item checks for an exact element in a list
test_to_contain_item() {
  local items=("diapers" "kleenex" "trash bags" "milk" "buttermilk")

  expect "$(printf '%s\n' "${items[@]}")" to_contain_item "milk"
  expect "$(printf '%s\n' "${items[@]}")" to_contain_item "trash bags"
  expect_failure "$(printf '%s\n' "${items[@]}")" to_contain_item "butter"
}

# @test to_be_empty, to_start_with, to_end_with
test_string_matchers() {
  expect "" to_be_empty
  expect "hello world" to_start_with "hello"
  expect "hello world" to_end_with "world"
  expect_failure "hello" to_be_empty
  expect_failure "hello world" to_start_with "world"
  expect_failure "hello world" to_end_with "hello"
}

# @test to_have_length counts characters, to_have_count counts list items
test_counting_matchers() {
  local items=("milk" "bread" "eggs")

  expect "hello" to_have_length 5
  expect "$(printf '%s\n' "${items[@]}")" to_have_count 3
  expect "" to_have_count 0
  expect_failure "hello" to_have_length 4
  expect_failure "$(printf '%s\n' "${items[@]}")" to_have_count 2
}

# @test to_exit_with checks the exit code of a command
test_to_exit_with() {
  expect "true" to_exit_with 0
  expect "false" to_exit_with 1
  expect "exit 7" to_exit_with 7
  expect_failure "true" to_exit_with 1
}

# @test not inverts any matcher
test_not() {
  expect "hello" not to_be_empty
  expect "hello" not to_contain "xyz"
  expect 3 not to_be_greater_than 5
  expect_failure "hello" not to_contain "ell"
  expect_failure "" not to_be_empty
}

# A fast test with a generous timeout passes
# @test a quick test finishes inside its timeout
# @timeout 5
test_within_timeout() {
  expect "ok" to_be "ok"
}
