#!/bin/bash

# shellcheck source=/dev/null
source /home/$USER/shest.sh

describe "Testing Assertions" <<'TEST'
  test "Testing toBeEqual" <<'SUITE'
    toBeEqual "hello" "hello"
    toBeEqual 1 1
  SUITE

  test "Testing toBeNotEqual" <<'SUITE'
    toBeNotEqual "hello" "world"
  SUITE

  test "Testing toBeTrue" <<'SUITE'
    toBeTrue true
  SUITE

  test "Testing toBeFalse" <<'SUITE'
    toBeFalse false
  SUITE

  test "Testing toContain" <<'SUITE'
    toContain "hello world" "world"
    toContain 123 2
  SUITE

  test "Testing toNotContain" <<'SUITE'
    toNotContain "hello world" "there"
    toNotContain 123 4
  SUITE

  test "Testing toStartWith" <<'SUITE'
    toStartWith "hello world" "hello"
    toStartWith "123" "1"
  SUITE

  test "Testing toEndWith" <<'SUITE'
    toEndWith "hello world" "world"
    toEndWith 123 3
  SUITE

  test "Testing toMatchRegex" <<'SUITE'
    toMatchRegex "abc123" "[a-z]+[0-9]+"
  SUITE

  test "Testing toExist" <<'SUITE'
    toExist $0
  SUITE

  test "Testing toBeFile" <<'SUITE'
    toBeFile "/etc/passwd"
  SUITE

  test "Testing toBeDirectory" <<'SUITE'
    toBeDirectory "/etc"
  SUITE

  test "Testing toBeGreaterThan" <<'SUITE'
    toBeGreaterThan 5 3
  SUITE

  test "Testing toBeLessThan" <<'SUITE'
    toBeLessThan 3 5
  SUITE
TEST
