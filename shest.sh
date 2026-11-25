#!/usr/bin/env bash

SHEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SHEST_DIR}/utils/colors.sh"

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1
readonly FIRST_TEST_INDEX=0
readonly INDEX_STEP=1
readonly INITIAL_FAILURE_COUNT=0
readonly TEST_FUNCTION_PREFIX='__test_'
readonly OUTPUT_INDENT='    '
readonly SINGLE_QUOTE="'"
readonly BEFORE_EACH_PATTERN='^@before_each[[:space:]]*\{[[:space:]]*$'
readonly AFTER_EACH_PATTERN='^@after_each[[:space:]]*\{[[:space:]]*$'
readonly BEFORE_ALL_PATTERN='^@before_all[[:space:]]*\{[[:space:]]*$'
readonly AFTER_ALL_PATTERN='^@after_all[[:space:]]*\{[[:space:]]*$'
readonly TEST_DECLARATION_PATTERN="^@test[[:space:]]+[\"${SINGLE_QUOTE}](.*)[\"${SINGLE_QUOTE}][[:space:]]*\{[[:space:]]*\$"

TEST_NAMES=()

to_be() {
  local actual="$1"
  local expected="$2"

  if [[ "$actual" != "$expected" ]]; then
    echo "Expected: $expected"
    echo "Received: $actual"
    return "$EXIT_FAILURE"
  fi
}

to_not_be_equal() {
  local actual="$1"
  local expected="$2"

  if [[ "$actual" == "$expected" ]]; then
    echo "Expected: $expected"
    echo "Received: $actual"
    return "$EXIT_FAILURE"
  fi
}

__before_each() { :; }
__after_each() { :; }
__before_all() { :; }
__after_all() { :; }

expect() {
  local actual="$1"
  local matcher="$2"
  shift 2

  "$matcher" "$actual" "$@"
}

preprocess() {
  local source_file="$1"
  local line
  local index="$FIRST_TEST_INDEX"

  while IFS= read -r line; do
    if [[ $line =~ $TEST_DECLARATION_PATTERN ]]; then
      TEST_NAMES+=("${BASH_REMATCH[1]}")
      echo "${TEST_FUNCTION_PREFIX}${index}() {"
      index=$((index + INDEX_STEP))
    elif [[ $line =~ $BEFORE_EACH_PATTERN ]]; then
      echo "__before_each() {"
    elif [[ $line =~ $BEFORE_ALL_PATTERN ]]; then
      echo "__before_all() {"
    elif [[ $line =~ $AFTER_ALL_PATTERN ]]; then
      echo "__after_all() {"
    elif [[ $line =~ $AFTER_EACH_PATTERN ]]; then
      echo "__after_each() {"
    else
      echo "$line"
    fi
  done < "$source_file"
}

run_tests() {
  local test_file="$1"
  local processed_file
  processed_file="$(mktemp)"

  preprocess "$test_file" > "$processed_file"
  source "$processed_file"
  rm -f "$processed_file"

  local failure_count="$INITIAL_FAILURE_COUNT"
  local index
  local output
  local status

  __before_all

  for index in "${!TEST_NAMES[@]}"; do
    output="$( ( set -e; trap __after_each EXIT; __before_each; "${TEST_FUNCTION_PREFIX}${index}" ) 2>&1 )"
    status=$?

    if [[ $status -eq $EXIT_SUCCESS ]]; then
      echo "${C_GREEN}✓${C_RESET} ${TEST_NAMES[$index]}"
      [[ -n $output ]] && echo "$output" | sed "s/^/${OUTPUT_INDENT}/"
    else
      echo "${C_RED}✗${C_RESET} ${TEST_NAMES[$index]}"
      echo "$output" | sed "s/^/${OUTPUT_INDENT}/"
      failure_count=$((failure_count + INDEX_STEP))
    fi
  done

  __after_all

  echo
  local passed=$(( ${#TEST_NAMES[@]} - failure_count ))
  local failed_color="$C_GREEN"
  [[ $failure_count -gt $INITIAL_FAILURE_COUNT ]] && failed_color="$C_RED"
  echo "${C_BOLD}${#TEST_NAMES[@]} tests${C_RESET}, ${C_GREEN}${passed} passed${C_RESET}, ${failed_color}${failure_count} failed${C_RESET}"

  if [[ $failure_count -gt $INITIAL_FAILURE_COUNT ]]; then
    return "$EXIT_FAILURE"
  fi
}

run_tests "$1"

# #!/usr/bin/env bash

# readonly EXIT_SUCCESS=0
# readonly EXIT_FAILURE=1
# readonly INITIAL_COUNT=0
# readonly COUNT_STEP=1
# readonly OUTPUT_INDENT='    '
# readonly TEST_FUNCTION_PREFIX='__test_'
# readonly TEST_REWRITE_PROGRAM='
# /^@test +\047.*\047 *\{$/ {
#   name = $0
#   sub(/^@test +\047/, "", name)
#   sub(/\047 *\{$/, "", name)
#   printf "TEST_NAMES[%d]=\047%s\047\n%s%d() {\n", count, name, prefix, count
#   count++
#   next
# }
# { print }
# '

# TEST_NAMES=()

# toBe() {
#   if [[ "$1" != "$2" ]]; then
#     echo "Expected: $2"
#     echo "Received: $1"
#     return "$EXIT_FAILURE"
#   fi
# }

# expect() {
#   local actual="$1"
#   local matcher="$2"
#   shift 2

#   "$matcher" "$actual" "$@"
# }

# run_tests() {
#   local test_file="$1"
#   local failure_count="$INITIAL_COUNT"
#   local index
#   local output
#   local status

#   eval "$(awk -v prefix="$TEST_FUNCTION_PREFIX" "$TEST_REWRITE_PROGRAM" "$test_file")"

#   for index in "${!TEST_NAMES[@]}"; do
#     output="$( ( set -e; "${TEST_FUNCTION_PREFIX}${index}" ) 2>&1 )"
#     status=$?

#     if [[ $status -eq $EXIT_SUCCESS ]]; then
#       echo "✓ ${TEST_NAMES[$index]}"
#     else
#       echo "✗ ${TEST_NAMES[$index]}"
#       echo "$output" | sed "s/^/${OUTPUT_INDENT}/"
#       failure_count=$((failure_count + COUNT_STEP))
#     fi
#   done

#   echo
#   echo "${#TEST_NAMES[@]} tests, ${failure_count} failed"

#   if [[ $failure_count -gt $INITIAL_COUNT ]]; then
#     return "$EXIT_FAILURE"
#   fi
# }

# run_tests "$1"
