source "$(dirname "${BASH_SOURCE[0]}")/arithmetic.sh"

# Only the happy path is tested, so coverage stays below 100%.

# @test divides 6 by 3
test_divide() {
  expect "$(divide 6 3)" to_be "2"
}
