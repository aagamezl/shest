#!/usr/bin/env bash

source ./sum.sh

readonly FIRST_ADDEND=1
readonly SECOND_ADDEND=2
readonly EXPECTED_SUM=3

test() {
  local description="$1"
  shift

  printf '%s ' "$description"

  if "$@"; then
    echo '✓'
  else
    echo '✗'
    return 1
  fi
}

expect() {
  local actual="$1"
  local matcher="$2"
  local expected="$3"

  echo "actual: $actual"
  echo "matcher: $matcher"
  echo "expected: $expected"

  case "$matcher" in
  toBe)
    [[ "$actual" == "$expected" ]]
    ;;
  *)
    echo "Unknown matcher: $matcher" >&2
    return 1
    ;;
  esac
}

test_addition() {
  expect "$(sum "$FIRST_ADDEND" "$SECOND_ADDEND")" toBe "$EXPECTED_SUM"
}

test 'adds 1 + 2 to equal 31' test_addition
