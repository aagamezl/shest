source "$(dirname "${BASH_SOURCE[0]}")/arithmetic.sh"

# shellcheck disable=SC2034
readonly FIRST_ADDEND=1
# shellcheck disable=SC2034
readonly SECOND_ADDEND=2
# shellcheck disable=SC2034
readonly EXPECTED_SUM=3

before_all() {
  echo "Do something before all tests"
}

after_all() {
  echo "Do something after all tests"
}

before_each() {
  echo "Do something before test"
}

after_each() {
  echo "Do something after each test"
}

# @test adds 1 + 2 to equal 3
test_adds_1_2_to_equal_3() {
  echo "testing"
  expect "$(sum "$FIRST_ADDEND" "$SECOND_ADDEND")" to_be "$EXPECTED_SUM"
}

# @test adds 1 + 3 to not be equal 3
test_adds_1_3_to_not_be_equal_3() {
  expect "$(sum "1" "3")" not_to_be "3"
}

# @test divide by zero fails
test_divide_by_zero() {
  if divide 1 0 2>/dev/null; then
    echo "should have failed"
    return 1
  fi
}
