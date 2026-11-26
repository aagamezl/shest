#!/usr/bin/env bash

SHEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SHEST_DIR}/utils/colors.sh"

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1
readonly INITIAL_FAILURE_COUNT=0
readonly OUTPUT_INDENT='    '
readonly TEST_ANNOTATION_PATTERN='^#[[:space:]]*@test(\.only|\.skip)?[[:space:]]+(.+)$'
readonly TEST_FILE_NAME_PATTERN='*.test.sh'
readonly DEFAULT_TEST_PATH='.'
SHEST_SELF="${SHEST_DIR}/$(basename "${BASH_SOURCE[0]}")"
readonly SHEST_SELF
readonly FUNCTION_DECLARATION_PATTERN='^(function[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*(\(\))?[[:space:]]*\{?'

TEST_NAMES=()
TEST_FUNCTIONS=()
TEST_MODES=()
NAME_FILTER=''

to_be() {
  local actual="$1"
  local expected="$2"

  if [[ "$actual" != "$expected" ]]; then
    echo "Expected: $expected"
    echo "Received: $actual"
    return "$EXIT_FAILURE"
  fi
}

not_to_be() {
  local actual="$1"
  local expected="$2"

  if [[ "$actual" == "$expected" ]]; then
    echo "Expected: $expected"
    echo "Received: $actual"
    return "$EXIT_FAILURE"
  fi
}

# Numeric comparison (supports decimals): __compare <a> <operator> <b>
__compare() {
  awk -v a="$1" -v b="$3" "BEGIN { exit !(a $2 b) }"
}

__assert_compare() {
  local actual="$1"
  local operator="$2"
  local expected="$3"
  local description="$4"

  if ! __compare "$actual" "$operator" "$expected"; then
    echo "Expected: ${actual} ${description} ${expected}"
    return "$EXIT_FAILURE"
  fi
}

to_be_greater_than() { __assert_compare "$1" '>' "$2" 'to be greater than'; }
to_be_greater_than_or_equal() { __assert_compare "$1" '>=' "$2" 'to be greater than or equal to'; }
to_be_less_than() { __assert_compare "$1" '<' "$2" 'to be less than'; }
to_be_less_than_or_equal() { __assert_compare "$1" '<=' "$2" 'to be less than or equal to'; }

to_be_true() {
  if [[ "$1" != "true" ]]; then
    echo "Expected: true"
    echo "Received: $1"
    return "$EXIT_FAILURE"
  fi
}

to_be_false() {
  if [[ "$1" != "false" ]]; then
    echo "Expected: false"
    echo "Received: $1"
    return "$EXIT_FAILURE"
  fi
}

# Extended regular expression match: expect "$text" to_match 'stop'
to_match() {
  if ! [[ "$1" =~ $2 ]]; then
    echo "Expected: to match /$2/"
    echo "Received: $1"
    return "$EXIT_FAILURE"
  fi
}

# Substring match: expect "$text" to_contain 'sub'
to_contain() {
  if [[ "$1" != *"$2"* ]]; then
    echo "Expected: to contain $2"
    echo "Received: $1"
    return "$EXIT_FAILURE"
  fi
}

# Exact element match on a newline-separated list:
#   expect "$(printf '%s\n' "${items[@]}")" to_contain_item milk
to_contain_item() {
  if ! grep -qxF -- "$2" <<<"$1"; then
    echo "Expected: list to contain item $2"
    echo "Received: ${1//$'\n'/, }"
    return "$EXIT_FAILURE"
  fi
}

# Default no-op hooks; a test file overrides them by defining functions
# with the same names.
before_each() { :; }
after_each() { :; }
before_all() { :; }
after_all() { :; }

expect() {
  local actual="$1"
  local matcher="$2"
  shift 2

  "$matcher" "$actual" "$@"
}

# Collect "# @test[.only|.skip] <name>" annotations and the function declared
# right after each one.
discover_tests() {
  local source_file="$1"
  local line
  local line_number=0
  local pending_name=''
  local pending_mode='run'
  local pending_line=0

  while IFS= read -r line; do
    line_number=$((line_number + 1))

    if [[ -n $pending_name ]]; then
      if [[ $line =~ $FUNCTION_DECLARATION_PATTERN ]]; then
        TEST_NAMES+=("$pending_name")
        TEST_FUNCTIONS+=("${BASH_REMATCH[2]}")
        TEST_MODES+=("$pending_mode")
        pending_name=''
        continue
      fi
      echo "${source_file}:${pending_line}: '# @test' must be followed by a function declaration" >&2
      return "$EXIT_FAILURE"
    fi

    if [[ $line =~ $TEST_ANNOTATION_PATTERN ]]; then
      pending_mode="${BASH_REMATCH[1]#.}"
      pending_mode="${pending_mode:-run}"
      pending_name="${BASH_REMATCH[2]}"
      pending_line=$line_number
    fi
  done <"$source_file"

  if [[ -n $pending_name ]]; then
    echo "${source_file}:${pending_line}: '# @test' must be followed by a function declaration" >&2
    return "$EXIT_FAILURE"
  fi
}

print_summary() {
  local total="$1" passed="$2" failed="$3" skipped="$4"
  local failed_color="$C_GREEN"
  if [[ $failed -gt 0 ]]; then
    failed_color="$C_RED"
  fi

  echo "${C_BOLD}${total} tests${C_RESET}, ${C_GREEN}${passed} passed${C_RESET}, ${failed_color}${failed} failed${C_RESET}, ${C_YELLOW}${skipped} skipped${C_RESET}"
}

# Print <text> with every line prefixed by OUTPUT_INDENT.
indent_output() {
  echo "${OUTPUT_INDENT}${1//$'\n'/$'\n'${OUTPUT_INDENT}}"
}

# Decide whether the test at <index> is skipped (skip / only / name filter).
is_skipped() {
  local index="$1"
  local has_only="$2"

  if [[ ${TEST_MODES[$index]} == skip ]]; then
    return 0
  fi
  if [[ $has_only == true && ${TEST_MODES[$index]} != only ]]; then
    return 0
  fi
  if [[ -n $NAME_FILTER && ! ${TEST_NAMES[$index]} =~ $NAME_FILTER ]]; then
    return 0
  fi
  return 1
}

# Run one test file in this process. When SHEST_RESULTS_FILE is set, append
# "<passed> <failed> <skipped>" to it instead of printing a summary.
run_tests() {
  local test_file="$1"

  discover_tests "$test_file" || return "$EXIT_FAILURE"
  # shellcheck disable=SC1090
  source "$test_file"

  local failed="$INITIAL_FAILURE_COUNT"
  local passed=0
  local skipped=0
  local has_only=false
  local index
  local output
  local status

  for index in "${!TEST_MODES[@]}"; do
    if [[ ${TEST_MODES[$index]} == only ]]; then
      has_only=true
    fi
  done

  local runnable=0
  for index in "${!TEST_NAMES[@]}"; do
    is_skipped "$index" "$has_only" || runnable=$((runnable + 1))
  done

  if [[ $runnable -gt 0 ]]; then
    before_all
  fi

  for index in "${!TEST_NAMES[@]}"; do
    if is_skipped "$index" "$has_only"; then
      echo "${C_YELLOW}○${C_RESET} ${C_DIM}${TEST_NAMES[$index]} (skipped)${C_RESET}"
      skipped=$((skipped + 1))
      continue
    fi

    output="$( (
      set -e
      trap after_each EXIT
      before_each
      "${TEST_FUNCTIONS[$index]}"
    ) 2>&1)"
    status=$?

    if [[ $status -eq $EXIT_SUCCESS ]]; then
      echo "${C_GREEN}✓${C_RESET} ${TEST_NAMES[$index]}"
      if [[ -n $output ]]; then
        indent_output "$output"
      fi
      passed=$((passed + 1))
    else
      echo "${C_RED}✗${C_RESET} ${TEST_NAMES[$index]}"
      indent_output "$output"
      failed=$((failed + 1))
    fi
  done

  if [[ $runnable -gt 0 ]]; then
    after_all
  fi

  if [[ -n ${SHEST_RESULTS_FILE:-} ]]; then
    echo "$passed $failed $skipped" >>"$SHEST_RESULTS_FILE"
  else
    echo
    print_summary "${#TEST_NAMES[@]}" "$passed" "$failed" "$skipped"
  fi

  [[ $failed -eq $INITIAL_FAILURE_COUNT ]]
}

usage() {
  cat <<'USAGE'
Usage: shest [options] [path...]

Options:
  -p, --path <glob|dir>...   Run test files matching the glob(s) or found in the directory(ies)
  -f, --file <file>...       Run the given test file(s)
  -t, --filter <regex>       Run only tests whose name matches the regex
  -h, --help                 Show this help

With no path, every *.test.sh under the current directory is run.
Quote globs (e.g. --path 'tests/**/*.test.sh') so shest expands them itself;
'**' matches any number of directories.

In a test file:
  # @test.skip <name>   skip this test
  # @test.only <name>   run only the tests marked .only in this file
USAGE
}

# Expand one path argument (file, directory or glob) to test files, one per line.
resolve_pattern() {
  local pattern="$1"
  local match
  local IFS=$'\n'

  if [[ -d $pattern ]]; then
    find "$pattern" -type f -name "$TEST_FILE_NAME_PATTERN" | sort
    return
  fi

  # "**" recursion is done with find so it behaves the same on bash 3.2 (macOS).
  if [[ $pattern == *'**'* ]]; then
    local prefix="${pattern%%\*\**}"
    prefix="${prefix%/}"
    find "${prefix:-.}" -type f \( -path "${pattern//\*\*/*}" -o -path "${pattern//\*\*\//}" \) | sort
    return
  fi

  shopt -s nullglob
  # shellcheck disable=SC2206
  for match in $pattern; do
    if [[ -f $match ]]; then
      echo "$match"
    fi
  done
}

run_files() {
  local test_file
  local total_files=0 failed_files=0
  local passed=0 failed=0 skipped=0
  local file_passed file_failed file_skipped
  local results_file
  results_file="$(mktemp)"

  for test_file in "$@"; do
    total_files=$((total_files + 1))
    echo "${C_BOLD}${test_file}${C_RESET}"

    SHEST_RESULTS_FILE="$results_file" bash "$SHEST_SELF" --run-file "$test_file" --filter "$NAME_FILTER" || failed_files=$((failed_files + 1))
    echo
  done

  while read -r file_passed file_failed file_skipped; do
    passed=$((passed + file_passed))
    failed=$((failed + file_failed))
    skipped=$((skipped + file_skipped))
  done <"$results_file"
  rm -f "$results_file"

  if [[ $total_files -gt 1 ]]; then
    echo "${C_BOLD}${total_files} files${C_RESET}, $((total_files - failed_files)) passed, ${failed_files} failed"
  fi
  print_summary "$((passed + failed + skipped))" "$passed" "$failed" "$skipped"

  [[ $failed_files -eq 0 ]]
}

main() {
  local patterns=()
  local run_file=''
  local files=()
  local pattern
  local test_file

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage
        return "$EXIT_SUCCESS"
        ;;
      -t | --filter)
        NAME_FILTER="${2:-}"
        shift 2 || break
        ;;
      --run-file)
        run_file="$2"
        shift 2
        ;;
      -p | --path | -f | --file)
        shift
        while [[ $# -gt 0 && $1 != -* ]]; do
          patterns+=("$1")
          shift
        done
        ;;
      -*)
        echo "shest: unknown option: $1" >&2
        usage >&2
        return "$EXIT_FAILURE"
        ;;
      *)
        patterns+=("$1")
        shift
        ;;
    esac
  done

  if [[ -n $run_file ]]; then
    run_tests "$run_file"
    return
  fi

  if [[ ${#patterns[@]} -eq 0 ]]; then
    patterns=("$DEFAULT_TEST_PATH")
  fi

  for pattern in "${patterns[@]}"; do
    while IFS= read -r test_file; do
      if [[ -n $test_file ]]; then
        files+=("$test_file")
      fi
    done < <(resolve_pattern "$pattern")
  done

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "shest: no test files found for: ${patterns[*]}" >&2
    return "$EXIT_FAILURE"
  fi

  run_files "${files[@]}"
}

main "$@"

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
