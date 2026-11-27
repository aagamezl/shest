# shellcheck shell=bash
# shellcheck disable=SC2016  # fixtures are written with single quotes on purpose
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

before_each() {
  make_workspace
  make_mixed_file a.test.sh
  add_test a.test.sh test.skip "skipped one" 'expect 1 to_be 2'
  add_todo a.test.sh "planned one"
}
after_each() { remove_workspace; }

# @test --reporter tap prints TAP on stdout and nothing else
test_tap() {
  run_shest a.test.sh --reporter tap
  expect "$STATUS" to_be 1
  expect "$(printf '%s\n' "$OUTPUT" | head -n 1)" to_be "TAP version 13"
  expect "$OUTPUT" to_contain "1..4"
  expect "$OUTPUT" to_contain "ok 1 - passes"
  expect "$OUTPUT" to_contain "not ok 2 - fails"
  expect "$OUTPUT" to_contain "ok 3 - skipped one # SKIP"
  expect "$OUTPUT" to_contain "not ok 4 - planned one # TODO"
  expect "$OUTPUT" to_contain "# fail 1"
  expect "$OUTPUT" not to_contain "Test Files"
}

# @test --reporter junit prints XML with failures and skips
test_junit() {
  run_shest a.test.sh --reporter junit
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_start_with '<?xml version="1.0" encoding="UTF-8"?>'
  expect "$OUTPUT" to_contain 'tests="4" failures="1" skipped="2"'
  expect "$OUTPUT" to_contain '<testcase classname="a.test.sh" name="passes"'
  expect "$OUTPUT" to_contain '<failure message="Expected: 2">'
  expect "$OUTPUT" to_contain '<skipped message="todo"/>'
}

# @test junit output is well-formed XML when xmllint is available
test_junit_well_formed() {
  if ! command -v xmllint >/dev/null; then
    return 0
  fi
  add_test a.test.sh test 'name with <special> & "chars"' 'echo "<b>&</b>"; expect 1 to_be 2'
  bash "$SHEST_BIN" a.test.sh --reporter junit >report.xml 2>/dev/null || true
  expect "xmllint --noout report.xml" to_exit_with 0
}

# @test --output-file writes the report and keeps the console output
test_output_file() {
  run_shest a.test.sh --reporter junit --output-file out.xml
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "Test Files:"
  expect "$(cat out.xml)" to_contain "<testsuites"
}

# @test an unknown reporter is rejected
test_unknown_reporter() {
  run_shest a.test.sh --reporter xml
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "unknown reporter: xml"
}
