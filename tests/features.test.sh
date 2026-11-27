# shellcheck shell=bash
# shellcheck disable=SC2016  # fixtures are written with single quotes on purpose
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

before_each() { make_workspace; }
after_each() { remove_workspace; }

# @test a test over its @timeout is killed, and after_each still runs
test_timeout_decorator() {
  printf 'after_each() { echo cleaned >>cleanup.log; }\n' >a.test.sh
  printf '# @test hangs\n# @timeout 0.3\nfixture_hang() {\n  sleep 5\n}\n\n' >>a.test.sh
  add_test a.test.sh test "fine" 'expect 1 to_be 1'
  run_shest a.test.sh
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "Timed out after 0.3s"
  expect "$OUTPUT" to_contain "✓ fine"
  expect "$(wc -l <cleanup.log | tr -d ' ')" to_be 2
}

# @test @timeout can sit above the @test line
test_timeout_above_test() {
  printf '# @timeout 0.3\n# @test hangs\nfixture_hang() {\n  sleep 5\n}\n' >a.test.sh
  run_shest a.test.sh
  expect "$OUTPUT" to_contain "Timed out after 0.3s"
}

# @test --timeout sets a limit for every test, and @timeout overrides it
test_timeout_flag() {
  add_test a.test.sh test "slow" 'sleep 5'
  printf '# @test generous\n# @timeout 10\nfixture_generous() {\n  sleep 0.2\n}\n' >>a.test.sh
  run_shest a.test.sh --timeout 0.3
  expect "$OUTPUT" to_contain "✗ slow"
  expect "$OUTPUT" to_contain "✓ generous"
}

# @test --parallel gives the same results and keeps the output in file order
test_parallel() {
  make_mixed_file a.test.sh
  add_test b.test.sh test "b passes" 'expect 1 to_be 1'
  add_test c.test.sh test "c passes" 'expect 1 to_be 1'
  run_shest a.test.sh b.test.sh c.test.sh --parallel 3
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "Test Files:  1 failed, 2 passed, 3 total"
  expect "$OUTPUT" to_contain "Tests:       1 failed, 3 passed, 4 total"
  expect "$(printf '%s\n' "$OUTPUT" | grep '━━' | tr '\n' ' ')" to_match 'a\.test\.sh.*b\.test\.sh.*c\.test\.sh'
}

# @test --parallel runs files at the same time
test_parallel_is_concurrent() {
  local start end
  add_test a.test.sh test "a" 'sleep 1'
  add_test b.test.sh test "b" 'sleep 1'
  add_test c.test.sh test "c" 'sleep 1'
  start="$(date +%s)"
  run_shest a.test.sh b.test.sh c.test.sh --parallel 3
  end="$(date +%s)"
  expect "$STATUS" to_be 0
  expect "$((end - start))" to_be_less_than 3
}

# @test --parallel with --bail starts no new files after a failure
test_parallel_bail() {
  make_mixed_file a.test.sh
  add_test b.test.sh test "b" 'expect 1 to_be 1'
  add_test c.test.sh test "c" 'expect 1 to_be 1'
  run_shest a.test.sh b.test.sh c.test.sh --parallel 1 --bail
  expect "$OUTPUT" to_contain "Bailed after the first failing file: 2 file(s) not run"
}

# @test --parallel keeps reporter events from every file
test_parallel_reporter() {
  add_test a.test.sh test "from a" 'expect 1 to_be 1'
  add_test b.test.sh test "from b" 'expect 1 to_be 1'
  run_shest a.test.sh b.test.sh --parallel 2 --reporter tap
  expect "$OUTPUT" to_contain "ok 1 - from a"
  expect "$OUTPUT" to_contain "ok 2 - from b"
}

# @test --list shows the tests without running them
test_list() {
  printf 'before_all() { touch ran.flag; }\n' >a.test.sh
  add_test a.test.sh test "normal" 'expect 1 to_be 2'
  add_test a.test.sh test.skip "skipped" 'true'
  add_todo a.test.sh "planned"
  printf '# @timeout 4\n# @test slow\nfixture_slow() {\n  true\n}\n' >>a.test.sh
  run_shest a.test.sh --list
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "• normal"
  expect "$OUTPUT" to_contain "○ skipped (skip)"
  expect "$OUTPUT" to_contain "✎ planned (todo)"
  expect "$OUTPUT" to_contain "• slow (timeout 4s)"
  expect "$OUTPUT" to_contain "Tests:       1 skipped, 1 todo, 2 to run, 4 total"
  expect "[ -e ran.flag ]" to_exit_with 1
}

# @test --list marks plain tests as skipped when the file has an .only
test_list_only() {
  add_test a.test.sh test "plain" 'true'
  add_test a.test.sh test.only "focus" 'true'
  run_shest a.test.sh --list
  expect "$OUTPUT" to_contain "○ plain (skip)"
  expect "$OUTPUT" to_contain "▶ focus (only)"
}

# @test --changed runs only tests affected by uncommitted changes
test_changed() {
  git init -q .
  git config user.email t@example.com
  git config user.name t
  printf 'one() { echo 1; }\n' >one.sh
  printf 'two() { echo 2; }\n' >two.sh
  printf 'source "$(dirname "${BASH_SOURCE[0]}")/one.sh"\n' >one.test.sh
  printf 'source "$(dirname "${BASH_SOURCE[0]}")/two.sh"\n' >two.test.sh
  add_test one.test.sh test "uses one" 'expect "$(one)" to_be 1'
  add_test two.test.sh test "uses two" 'expect "$(two)" to_be 2'
  git add . && git -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q -m init

  run_shest --changed
  expect "$STATUS" to_be 0
  expect "$OUTPUT" to_contain "no test files are affected"

  printf 'one() { echo 1; } # edited\n' >one.sh
  run_shest --changed
  expect "$OUTPUT" to_contain "uses one"
  expect "$OUTPUT" not to_contain "uses two"

  printf '# edited\n' >>two.test.sh
  run_shest --changed
  expect "$OUTPUT" to_contain "uses two"
}

# @test --changed outside a git repository fails clearly
test_changed_without_git() {
  add_test a.test.sh test "a" 'true'
  GIT_CEILING_DIRECTORIES="$(dirname "$PWD")" run_shest --changed
  expect "$STATUS" to_be 1
  expect "$OUTPUT" to_contain "--changed needs a git repository"
}

# @test --watch re-runs after a file changes
test_watch() {
  add_test a.test.sh test "watched" 'true'
  bash "$SHEST_BIN" a.test.sh --watch >watch.log 2>&1 &
  local pid=$!
  sleep 2
  touch a.test.sh
  sleep 3
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  expect "$(grep -c 'Test Files:' watch.log)" to_be_greater_than_or_equal 2
  expect "$(cat watch.log)" to_contain "Watching for changes"
}
