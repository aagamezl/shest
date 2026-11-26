# shellcheck shell=bash
source "$(dirname "${BASH_SOURCE[0]}")/arithmetic.sh"
# Intentionally failing tests, to eyeball the failure output of each matcher.
# Run: bash shest.sh failing.test.sh

# @test to_be_greater_than fails
test_fail_greater_than() {
  expect 2 to_be_greater_than 3
}

# @test to_be_greater_than_or_equal fails
test_fail_greater_than_or_equal() {
  expect 3 to_be_greater_than_or_equal 3.5
}

# @test to_be_less_than fails
test_fail_less_than() {
  expect 5 to_be_less_than 5
}

# @test to_be_less_than_or_equal fails
test_fail_less_than_or_equal() {
  expect 5 to_be_less_than_or_equal 4.5
}

# @test to_be_true fails
test_fail_to_be_true() {
  expect false to_be_true
}

# @test to_be_false fails
test_fail_to_be_false() {
  expect true to_be_false
}

# @test to_match fails
test_fail_to_match() {
  expect "Christoph" to_match '^stop'
}

# @test to_contain fails
test_fail_to_contain() {
  expect "milk and bread" to_contain "eggs"
}

# @test to_contain_item fails
test_fail_to_contain_item() {
  local items=("diapers" "kleenex" "milk")

  expect "$(printf '%s\n' "${items[@]}")" to_contain_item "butter"
}

# @test to_be fails
test_fail_to_be() {
  expect "$(sum 1 2)" to_be "4"
}

# @test a passing test among the failures
test_passes() {
  expect 1 to_be_less_than 2
}
