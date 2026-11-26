source "$(dirname "${BASH_SOURCE[0]}")/validators.sh"

# @test is_number accepts integers
test_is_number() {
  is_number "42"
  is_number "-7"
}

# @test is_email accepts a valid address
test_is_email() {
  is_email "dev@example.com"
}
