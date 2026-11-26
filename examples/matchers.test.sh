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
