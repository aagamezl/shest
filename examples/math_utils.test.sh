source "$(dirname "${BASH_SOURCE[0]}")/math_utils.sh"

# @test max returns the larger number
test_max() {
  expect "$(max 3 7)" to_be "7"
}

# @test min returns the smaller number
test_min() {
  expect "$(min 3 7)" to_be "3"
}

# @test abs of a positive number is unchanged
test_abs_positive() {
  expect "$(abs 5)" to_be "5"
}

# @test factorial of 5 is 120
test_factorial() {
  expect "$(factorial 5)" to_be "120"
}
