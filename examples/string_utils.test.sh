source "$(dirname "${BASH_SOURCE[0]}")/string_utils.sh"

# @test to_upper uppercases a string
test_to_upper() {
  expect "$(to_upper "hello")" to_be "HELLO"
}

# @test repeat_string repeats a string
test_repeat_string() {
  expect "$(repeat_string "ab" 3)" to_be "ababab"
}

# @test is_blank detects blank strings
test_is_blank() {
  is_blank "   "
  expect "$(is_blank "x" && echo yes || echo no)" to_be "no"
}
