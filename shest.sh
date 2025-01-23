#!/bin/bash

VERSION="1.0.1"

#------------------------------START COLORS FORMAT------------------------------
FMT_RESET='\033[0m' # Color Off
FMT_BLUE='\033[34m'
FMT_BOLD='\033[1m'
FMT_CYAN='\033[0;36m'
FMT_GREEN='\033[0;32m'
FMT_RED='\033[0;31m'
#-------------------------------END COLORS FORMAT-------------------------------

#---------------------------START UTILITIES UTILITIES---------------------------
#----------------------------END UTILITIES UTILITIES----------------------------

#---------------------------START ASSERTION UTILITIES---------------------------
function toBeEqual() {
  local expected=$1
  local received=$2

  if [[ "$received" == "$expected" ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} ${FUNCNAME}: Expected: '${FMT_GREEN}$expected${FMT_RESET}', Received: '${FMT_RED}$received${FMT_RESET}'" >&2

    echo 0
  fi
}

function toBeNotEqual() {
  local expected=$1
  local received=$2

  if [[ "$received" != "$expected" ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} ${FUNCNAME}: Expected: '${FMT_GREEN}$expected${FMT_RESET}', Received: '${FMT_RED}$received${FMT_RESET}'" >&2

    echo 0
  fi
}

function toBeTrue() {
  local received=$1

  if [[ $received == true ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected ${FMT_RED}$received${FMT_RESET} to be true" >&2

    echo 0
  fi
}

function toBeFalse() {
  local received=$1

  if [[ $received == false ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected ${FMT_RED}$received${FMT_RESET} to be false" >&2

    echo 0
  fi
}

function toContain() {
  local expected=$1
  local received=$2

  if [[ $expected == *"$received"* ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '${FMT_GREEN}$expected${FMT_RESET}' to contain '${FMT_RED}$received${FMT_RESET}'" >&2

    echo 0
  fi
}

function toNotContain() {
  local expected=$1
  local received=$2

  if [[ $expected != *"$received"* ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '${FMT_GREEN}$expected${FMT_RESET}' to not contain '${FMT_RED}$received${FMT_RESET}'" >&2

    echo 0
  fi
}

function toStartWith() {
  local expected=$1
  local received=$2

  if [[ "$expected" == "$received"* ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '${FMT_GREEN}$expected${FMT_RESET}' to start with '${FMT_RED}$received${FMT_RESET}'" >&2

    echo 0
  fi
}

function toEndWith() {
  local expected=$1
  local received=$2

  if [[ "$expected" == *"$received" ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '${FMT_GREEN}$expected${FMT_RESET}' to end with '${FMT_RED}$received${FMT_RESET}'" >&2

    echo 0
  fi
}

function toMatchRegex() {
  local expected=$1
  local received=$2

  if [[ "$expected" =~ $received ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} toMatchRegex: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '${FMT_GREEN}$expected${FMT_RESET}' to match regex '${FMT_RED}$received${FMT_RESET}'" >&2

    echo 0
  fi
}

function toExist() {
  local received=$1

  if [[ -e $received ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} $FUNCNAME: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '${FMT_RED}$received${FMT_RESET}' to exist" >&2

    echo 0
  fi
}

function toBeFile() {
  if [[ -f "$1" ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} toBeFile: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '$1' to be a file" >&2

    echo 0
  fi
}

function toBeDirectory() {
  if [[ -d "$1" ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} toBeDirectory: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '$1' to be a directory" >&2

    echo 0
  fi
}

function toBeGreaterThan() {
  if [[ "$1" -gt "$2" ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} toBeGreaterThan: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '$1' to be greater than '$2'" >&2

    echo 0
  fi
}

function toBeLessThan() {
  if [[ "$1" -lt "$2" ]]; then
    echo -e "    ${FMT_GREEN}✓${FMT_RESET} toBeLessThan: Passed" >&2

    echo 1
  else
    echo -e "    ${FMT_RED}✗${FMT_RESET} $FUNCNAME: Expected '$1' to be less than '$2'" >&2

    echo 0
  fi
}
#----------------------------END ASSERTION UTILITIES----------------------------

#----------------------------START TESTING FUNCTIONS----------------------------
function describe() {
  local describe_name=$1
  local passed=0
  local failed=0
  local test_block
  local test_result
  local passed_test_suites=0
  local failed_test_suites=0
  local start_time=0
  local end_time=0
  local elapsed=0

  echo -e "${FMT_CYAN}• $describe_name${FMT_RESET}"

  start_time=$(date +%s.%N) # Record the start time

  # Read lines from stdin (HereDoc content)
  while IFS= read -r line; do
    test_block+=$line$'\n'
  done

  test_block=$(echo "$test_block" | sed 's/^  //')
  test_result=$(eval "$test_block")

  IFS=',' read -a array <<<"$test_result"

  for ((i = 0; i < ${#array[@]}; i += 2)); do
    passed=$((passed + array[i]))
    failed=$((failed + array[i + 1]))

    if [[ ${array[i + 1]} == 0 ]]; then
      passed_test_suites=$((passed_test_suites + 1))
    else
      failed_test_suites=$((failed_test_suites + 1))
    fi
  done

  end_time=$(date +%s.%N) # Record the end time
  elapsed=$(echo "$end_time - $start_time" | bc)

  echo -e "    Test Suites: \t${FMT_RED}${failed_test_suites} failed${FMT_RESET}, ${FMT_GREEN}$passed_test_suites passed${FMT_RESET}, $((passed_test_suites + failed_test_suites)) total"
  echo -e "    Tests: \t\t${FMT_RED}${failed} failed${FMT_RESET}, ${FMT_GREEN}$passed passed${FMT_RESET}, $((passed + failed)) total"
  printf "    Time: \t\t%.2f s\n" "$elapsed"
  echo >&2

  # [[ "$failed_test_suites" -eq 0 ]] && exit 0 || exit 1
}

function test() {
  local test_name=$1
  local passed=0
  local failed=0
  local assertion_result

  echo -e "  ${FMT_YELLOW}$test_name${FMT_RESET}" >&2

  while IFS= read -r line; do
    assertion_result=$(eval "$line")

    if [[ $assertion_result == 1 ]]; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo >&2
  echo -n "$passed,$failed,"
}
#-----------------------------END TESTING FUNCTIONS-----------------------------
