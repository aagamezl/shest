# shest

`shest` (**Sh**ell T**est**) is a test runner for Bash, inspired by Jest. Tests are plain, valid Bash functions marked with a comment annotation, so test files pass `bash -n`, ShellCheck and `shfmt` like any other script.

```bash
# @test adds 1 + 2 to equal 3
test_adds() {
  expect "$(sum 1 2)" to_be "3"
}
```

## Features

- Valid-bash test files: no preprocessing, linters and editors just work
- `expect <actual> <matcher> [expected]` assertions with numeric, boolean, regex and list matchers
- `before_all`, `after_all`, `before_each`, `after_each` hooks
- Run one file, many files, a directory or a recursive glob (`tests/**/*.test.sh`)
- Skip tests (`@test.skip`), focus tests (`@test.only`), plan tests (`@test.todo`) or filter by name (`--filter`)
- Per-test timeouts (`# @timeout`) so a hung test cannot block the run
- Run files in parallel (`--parallel`), re-run on changes (`--watch`) or only the tests affected by git changes (`--changed`)
- `--list` shows the discovered tests without running them
- Line coverage with a Jest-style table, an optional failing threshold, and `lcov` / Cobertura files
- Stop at the first failing file (`--bail`) and per-test timing (`--timing`)
- TAP and JUnit XML reports for CI (`--reporter`)
- A `shest.config.sh` config file (`shest --init` creates one)
- Total run time, colored output, and a non-zero exit code on failure (CI friendly)
- Works on macOS bash 3.2 as well as bash 4/5
- One-line installer, upgrade and uninstall

## Installation

### One-line Installer

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aagamezl/shest/master/bin/install.sh)"
```

or non-interactively (for CI and scripts):

```bash
curl -fsSL https://raw.githubusercontent.com/aagamezl/shest/master/bin/install.sh | sh -s -- --yes
```

The installer:

1. Downloads the repository (`curl` and `tar` are required).
2. Copies `shest` and `utils/` into `~/.shest`.
3. Links `~/.local/bin/shest` to `~/.shest/shest`, so you can run `shest` from anywhere.
4. Warns you if `~/.local/bin` is not in your `PATH`, with the line to add to your shell profile.

Running it again upgrades shest (it asks first unless you pass `--yes`) or tells you that you already have the latest version.

```bash
shest --version
```

| Option        | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| `-y, --yes`   | Do not ask for confirmation when upgrading or uninstalling   |
| `--uninstall` | Remove shest                                                 |
| `-h, --help`  | Show the installer help                                      |

| Environment variable | Default        | Description                                          |
| -------------------- | -------------- | ---------------------------------------------------- |
| `SHEST_INSTALL_DIR`  | `~/.shest`     | Where shest is installed                             |
| `SHEST_BIN_DIR`      | `~/.local/bin` | Where the `shest` link is created                    |
| `SHEST_REF`          | `master`       | Branch or tag to download                            |
| `SHEST_SOURCE_DIR`   | (none)         | Install from a local checkout instead of downloading |

To uninstall:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aagamezl/shest/master/bin/install.sh)" -- --uninstall
```

### From A Clone

```bash
git clone https://github.com/aagamezl/shest.git
./shest/shest --help
```

`shest` loads `utils/colors.sh` (and `utils/ui/box-ui.sh` for `--help`) from its own directory, so keep `shest` and `utils/` together. A symlink to `shest` works, since `shest` resolves it to find its files.

The examples below call `shest`. If you installed with the installer, use `shest` instead.

## Quick Start

Create `sum.sh`:

```bash
sum() {
  echo $(($1 + $2))
}
```

Create `sum.test.sh`:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/sum.sh"

# @test adds 1 + 2 to equal 3
test_adds() {
  expect "$(sum 1 2)" to_be "3"
}

# @test adds 1 + 3 to not be equal 3
test_not_equal() {
  expect "$(sum 1 3)" not_to_be "3"
}
```

Run it:

```bash
shest --file sum.test.sh
```

```text
━━ sum.test.sh ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ adds 1 + 2 to equal 3
✓ adds 1 + 3 to not be equal 3

────────────────────────────────────────────────────────────────────
Test Files:  1 passed, 1 total
Tests:       2 passed, 2 total
Time:        0.05s
```

> Source your code relative to the test file (`$(dirname "${BASH_SOURCE[0]}")`) rather than `./file.sh`, so tests work no matter which directory you run `shest` from.

## Decorators

`shest` uses **decorators** to declare tests. A decorator is a special comment placed on the line directly above a function. It tells `shest` that the function is a test, what to call it, and whether to run or skip it.

```bash
# @test adds two numbers
test_adds() {
  expect "$(sum 1 2)" to_be "3"
}
```

Here `# @test adds two numbers` is the decorator and `test_adds` is the function it decorates.

Because a decorator is just a comment, Bash ignores it. The file stays valid Bash, so `bash -n`, ShellCheck and `shfmt` accept it. Only `shest` reads decorators: it scans the file for them before running anything.

### Syntax

```text
# @test[.modifier] <name>
function_name() {
```

| Part        | Meaning                                                                         |
| ----------- | ------------------------------------------------------------------------------- |
| `#`         | starts the comment (spaces after it are optional: `#@test` and `#  @test` work) |
| `@test`     | marks the next function as a test                                               |
| `.modifier` | optional: `.skip`, `.only` or `.todo` (see below)                               |
| `<name>`    | the display name for the report: free text, spaces and symbols allowed          |

| Decorator             | Effect                                                              |
| --------------------- | ------------------------------------------------------------------- |
| `# @test <name>`      | register the next function as a test                                |
| `# @test.skip <name>` | register it but do not run it (reported as skipped)                 |
| `# @test.only <name>` | run only the `.only` tests of this file; the others are skipped     |
| `# @test.todo <name>` | a planned test: listed as todo, needs no function                   |
| `# @timeout <seconds>`| kill the test when it runs longer (see [Timeouts](#timeouts))       |

Rules:

- The decorator must be **immediately followed by the function declaration**: no blank line, comment or other code in between, except a `# @timeout` line. Otherwise `shest` stops with an error pointing at the file and line. `.todo` is the exception: it needs no function.
- The function name is up to you (`test_adds`, `adds`, ...). Only the decorator text is used as the name in the report. Use unique function names, because the last definition of a name wins.
- A function without a decorator is a normal helper and never runs as a test.
- The lifecycle hooks (`before_all`, `after_all`, `before_each`, `after_each`) are **not** decorators. They are recognized by their function names. See [Hooks](#hooks).

## Writing Tests

### Tests

A test is a function preceded by a `# @test <name>` [decorator](#decorators). The text after `@test` is the name shown in the report, so it can contain spaces and symbols.

```bash
# @test greets the user by name
test_greet() {
  expect "$(greet bob)" to_be "hi bob"
}
```

Both `name() {` and `function name {` declarations work. If a `# @test` comment is not followed by a function, shest stops with an error pointing at the file and line:

```text
sum.test.sh:12: '# @test' must be followed by a function declaration
```

A test passes when the function finishes with every command succeeding (it runs with `set -e`) and fails otherwise. Anything the test prints is shown indented below its result.

### Hooks

Define functions with these exact names to run code around your tests. They are optional.

| Function      | Runs                                        |
| ------------- | ------------------------------------------- |
| `before_all`  | once, before the first test of the file     |
| `after_all`   | once, after the last test of the file       |
| `before_each` | before every test                           |
| `after_each`  | after every test, even when the test fails  |

```bash
before_all() {
  TMP_DIR="$(mktemp -d)"
}

after_all() {
  rm -rf "$TMP_DIR"
}
```

`before_all` and `after_all` are skipped when no test in the file runs (for example when everything is skipped).

### Skipping And Focusing

```bash
# @test.skip not ready yet
test_pending() {
  expect 1 to_be 2
}

# @test.only run just this one
test_focused() {
  expect 1 to_be 1
}
```

- `# @test.skip` marks a test as skipped. It is printed as `○ name (skipped)` and counted in the summary.
- `# @test.only` runs only the `.only` tests of that file, and the others are skipped.
- `--filter <regex>` runs only the tests whose name matches the regular expression.

### Todo Tests

`# @test.todo <name>` records a test you plan to write. It needs no function, is printed as `✎ name (todo)`, and is counted separately in the summary. It never fails the run.

```bash
# @test.todo handles empty input
# @test.todo reports an error for a negative number
```

```text
✎ handles empty input (todo)
✎ reports an error for a negative number (todo)
```

In TAP reports a todo is `not ok ... # TODO`, and in JUnit it is a `<skipped message="todo"/>`.

### Timeouts

A test that runs longer than its limit is killed and fails with `Timed out after <n>s`, so a hung test cannot block the run. `after_each` still runs.

```bash
# @test downloads the file
# @timeout 10
test_download() {
  curl -fsS "$URL" -o out.bin
}
```

- `# @timeout <seconds>` goes right above `# @test` or between it and the function. Decimals work (`# @timeout 0.5`).
- `TEST_TIMEOUT=30` in the [config file](#configuration), or `--timeout 30` on the command line, sets a limit for every test. A `# @timeout` line overrides it, and `0` means no limit.
- The limit covers `before_each`, the test and `after_each` of that test, not `before_all` / `after_all`.

## Assertions

Use `expect <actual> <matcher> [expected]`. Matchers print `Expected` / `Received` details when they fail.

| Matcher                        | Passes when                                   | Example                                             |
| ------------------------------ | --------------------------------------------- | --------------------------------------------------- |
| `to_be`                        | the strings are equal                         | `expect "$x" to_be "3"`                             |
| `not_to_be`                    | the strings are different                     | `expect "$x" not_to_be "3"`                         |
| `to_be_greater_than`           | actual `>` expected (decimals supported)      | `expect 4 to_be_greater_than 3`                     |
| `to_be_greater_than_or_equal`  | actual `>=` expected                          | `expect 3.5 to_be_greater_than_or_equal 3.5`        |
| `to_be_less_than`              | actual `<` expected                           | `expect 4 to_be_less_than 5`                        |
| `to_be_less_than_or_equal`     | actual `<=` expected                          | `expect 4.5 to_be_less_than_or_equal 4.5`           |
| `to_be_true`                   | the value is exactly `true`                   | `expect "$flag" to_be_true`                         |
| `to_be_false`                  | the value is exactly `false`                  | `expect "$flag" to_be_false`                        |
| `to_match`                     | the value matches an extended regex           | `expect "Christoph" to_match 'stop'`                |
| `to_contain`                   | the value contains a substring                | `expect "milk and bread" to_contain "milk"`         |
| `to_contain_item`              | a newline-separated list has the exact item   | see below                                           |
| `to_be_empty`                  | the value is the empty string                 | `expect "$out" to_be_empty`                         |
| `to_start_with`                | the value starts with a prefix                | `expect "hello world" to_start_with "hello"`        |
| `to_end_with`                  | the value ends with a suffix                  | `expect "hello world" to_end_with "world"`          |
| `to_have_length`               | the value has this many characters            | `expect "hello" to_have_length 5`                   |
| `to_have_count`                | a newline-separated list has this many items  | see below                                           |
| `to_exit_with`                 | a command line exits with this code           | `expect "grep -q x f.txt" to_exit_with 1`           |

Shell arrays cannot be passed as a single argument, so join them with `printf` for `to_contain_item`. It matches whole items, so `milk` is not found inside `buttermilk`:

```bash
items=("diapers" "milk" "buttermilk")
expect "$(printf '%s\n' "${items[@]}")" to_contain_item "milk"
```

Use `to_have_count` with the same `printf` trick, and `to_exit_with` to check exit codes:

```bash
expect "$(printf '%s\n' "${items[@]}")" to_have_count 3
expect "" to_have_count 0                    # an empty list has 0 items
expect "false" to_exit_with 1                # the command is run with eval in a subshell, output discarded
```

### Negating A Matcher

Put `not` before any matcher to invert it, including custom ones:

```bash
expect "hello" not to_be_empty
expect "hello" not to_contain "xyz"
expect 3 not to_be_greater_than 5
```

On failure it prints `Expected: not to contain xyz` and the received value. `not_to_be` still works too.

### Custom Matchers

A matcher is any function that receives the actual value first and returns non-zero to fail:

```bash
to_be_even() {
  if (($1 % 2 != 0)); then
    echo "Expected: $1 to be even"
    return 1
  fi
}

# @test 4 is even
test_even() {
  expect 4 to_be_even
}
```

## Running Tests

```text
shest [options] [path...]
```

| Option                         | Description                                                              |
| ------------------------------ | ------------------------------------------------------------------------ |
| `-p, --path <glob\|dir>...`    | Run test files matching the glob(s), or every `*.test.sh` in a directory |
| `-f, --file <file>...`         | Run the given test file(s)                                               |
| `-t, --filter <regex>`         | Run only tests whose name matches                                        |
| `--coverage`                   | Print a line coverage report                                             |
| `--coverage-threshold <n>`     | Fail when total coverage is below `n` percent (implies `--coverage`)     |
| `--coverage-reporters <list>`  | Comma list of `text`, `lcov`, `cobertura` (see [Code Coverage](#code-coverage)) |
| `--coverage-directory <dir>`   | Where the `lcov` / `cobertura` files are written (default `coverage`)    |
| `--parallel <n>`               | Run up to `n` test files at the same time                                |
| `--timeout <seconds>`          | Kill any test that runs longer than this (see [Timeouts](#timeouts))     |
| `--changed`                    | Only run tests affected by files changed in git                          |
| `--list`                       | List the discovered tests without running them                           |
| `--watch`                      | Re-run when a `.sh` file changes                                         |
| `--init`                       | Create a commented `shest.config.sh`                                     |
| `--config <file>`              | Use this config file (default `shest.config.sh`)                         |
| `--bail`                       | Stop after the first failing file                                        |
| `--timing`                     | Show how long each test took                                             |
| `--reporter <name>`            | `default`, `tap` or `junit` (see [Reporters](#reporters))                |
| `--output-file <file>`         | Write the `tap` / `junit` report to a file instead of stdout             |
| `-v, --version`                | Show the version                                                         |
| `-h, --help`                   | Show help                                                                |

```bash
shest                                   # every *.test.sh under the current directory
shest --file sum.test.sh                # one file
shest --path tests/                     # a directory, recursively
shest --path 'tests/**/*.test.sh'       # a glob (quote it so shest expands it)
shest --path a.test.sh b.test.sh        # several paths
shest -t 'greater' --file matchers.test.sh
```

- Quote globs so shest expands them itself. `**` matches any number of directories on every bash version.
- Each file runs in its own process, so functions and variables never leak between files.
- The exit code is `1` when any test or file fails, a coverage threshold is missed, or no test files are found. Otherwise it is `0`.

### Parallel Runs

`--parallel <n>` runs up to `n` test files at once. Files already run in separate processes, so nothing else changes:

```bash
shest --parallel 4
```

- Output stays grouped: each file's results are printed in order once it finishes, never interleaved, and colors are kept.
- Counts, coverage, reports and the exit code are the same as a sequential run.
- With `--bail`, files that already started finish, and no new ones start after the first failure.
- It helps when files are slow (waiting on `sleep`, the network or a build). The run can never be faster than the slowest single file, and for files that finish in milliseconds the extra processes bring no gain. For example, six files that each `sleep 1` take 6.3s with `--parallel 1`, 2.3s with `--parallel 3` and 1.2s with `--parallel 6`.
- Tests that share a file, a port or a database can interfere when run in parallel. Keep it at `1` (the default) for those.

### Listing Tests

`--list` discovers tests without running them or running any hook. It honors paths, ignore patterns, `--filter` and `--changed`:

```bash
shest --list --path 'tests/**/*.test.sh'
```

```text
━━ examples/skipping.test.sh ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• runs normally
○ fails if it ever runs (skip)
✎ handles empty input (todo)

━━ examples/only.test.sh ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
○ not run because another test is .only (skip)
▶ the only one that runs (only)

────────────────────────────────────────────────────────────────────
Test Files:  2
Tests:       2 skipped, 1 todo, 1 only, 2 to run, 5 total
```

Each file gets the same header as a real run. `•` (green) is a test that will run, `○` (yellow) is skipped, `✎` (cyan) is todo, and `▶` (blue) is `.only`. Plain tests in a file that has an `.only` test are shown as skipped, because that is what a run would do. A `(timeout Ns)` note is added to tests with a `# @timeout`. The summary counts skipped, todo, only, how many would run, and the total.

### Changed Files

`--changed` runs only the tests affected by uncommitted work (modified, staged and untracked files, from `git`). A test file is selected when it changed itself or when its text mentions the file name of a changed source file, so a test that `source`s `arithmetic.sh` runs when `arithmetic.sh` changes.

```bash
shest --changed
shest --changed --coverage
```

If nothing is affected it prints `no test files are affected by the changed files` and exits `0`. It needs a git repository.

### Watch Mode

`--watch` runs the tests, then waits and runs them again whenever a `.sh` file under the current directory changes (the screen is cleared between runs on a terminal). Other options are kept, so it combines with filters, `--changed` and coverage. Press Ctrl-C to quit.

```bash
shest --watch
shest --watch --changed --filter 'adds'
```

### Report

Each file gets a header, failing tests are followed by their details and a blank line, and a summary closes the run:

```text
━━ examples/matchers.test.sh ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ to_be_greater_than passes for a larger number
...

━━ examples/failing.test.sh ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✗ to_be_greater_than fails
    Expected: 2 to be greater than 3

✗ to_be_true fails
    Expected: true
    Received: false

────────────────────────────────────────────────────────────────────
Test Files:  1 failed, 9 passed, 10 total
Tests:       3 skipped, 2 todo, 11 failed, 33 passed, 49 total
Time:        0.73s
```

- `Test Files` counts files. A file fails when any of its tests fail or it cannot be loaded.
- `Tests` counts individual tests: skipped (yellow), todo (cyan), failed (red) and passed (green), then the total. Zero counts are omitted, except `passed`.
- The summary is always the last thing printed, after the coverage report.
- `Time` is the total wall-clock time (sub-second precision with bash 5 or `perl`; whole seconds otherwise).

### Bail

`--bail` stops the run after the first file that fails. The files that were not run are counted and reported:

```text
Test Files:  1 failed, 1 passed, 2 total
Tests:       10 failed, 2 passed, 12 total
Time:        0.17s

Bailed after the first failing file: 8 file(s) not run
```

### Colors

Output is colored only when stdout is a terminal. Set `NO_COLOR=1` (or use `TERM=dumb`) to turn colors off, for example in CI logs:

```bash
NO_COLOR=1 shest
```

Piped or redirected output, and the `tap` / `junit` reports, never contain color codes.

### Timing

`--timing` prints the duration of every test:

```text
✓ adds 1 + 2 to equal 3 (15 ms)
✓ adds 1 + 3 to not be equal 3 (12 ms)
```

Timing uses sub-second precision with bash 5 or `perl`. On older systems without `perl` it falls back to whole seconds.

### Reporters

Besides the default console output, `shest` can produce machine-readable reports for CI:

```bash
shest --reporter tap --path tests/                          # TAP on stdout
shest --reporter junit --path tests/ > report.xml           # JUnit XML on stdout
shest --reporter junit --output-file report.xml --path tests/
```

- With `--reporter tap` or `--reporter junit`, the report is the only thing printed on stdout. The exit code is unchanged.
- With `--output-file <file>`, the console output is printed as usual and the report is written to the file.
- Both formats include every test (passed, failed and skipped), the file it belongs to, and the output of failed tests. JUnit also records each test's duration, grouped in one `<testsuite>` per file.

TAP (version 13):

```text
TAP version 13
1..3
ok 1 - runs normally
ok 2 - is skipped # SKIP
not ok 3 - fails
  ---
  file: examples/failing.test.sh
  output: |
    Expected: 2 to be greater than 3
  ...
# tests 3
# pass 1
# fail 1
# skip 1
```

JUnit:

```xml
<testsuites name="shest" tests="3" failures="1" skipped="1" time="0.070">
  <testsuite name="examples/failing.test.sh" tests="3" failures="1" skipped="1" time="0.050">
    <testcase classname="examples/failing.test.sh" name="runs normally" time="0.015"/>
    <testcase classname="examples/failing.test.sh" name="fails" time="0.018">
      <failure message="Expected: 2 to be greater than 3">Expected: 2 to be greater than 3</failure>
    </testcase>
  </testsuite>
</testsuites>
```

## Code Coverage

```bash
shest --path 'examples/**/*.test.sh' --coverage
shest --file examples/divide.test.sh --coverage-threshold 80
```

```text
┌──────────────────────────┬─────────┬───────┬───────────────────┐
│ File                     │ % Lines │ Lines │ Uncovered Line #s │
├──────────────────────────┼─────────┼───────┼───────────────────┤
│ All files                │   73.68 │ 28/38 │                   │
│ examples/arithmetic.sh   │   83.33 │   5/6 │ 15                │
│ examples/math_utils.sh   │   80.00 │ 12/15 │ 5,15,21           │
│ examples/string_utils.sh │  100.00 │   9/9 │                   │
│ examples/validators.sh   │   25.00 │   2/8 │ 12,16-17,20-21,24 │
└──────────────────────────┴─────────┴───────┴───────────────────┘

Coverage: 73.68% (28/38 lines)
```

- The table follows the Jest layout: an `All files` row first, then one row per file, with the percentage of covered lines, `covered/total` lines and the uncovered line numbers (consecutive lines are shown as ranges).
- The total percentage is repeated under the table, and it is what `--coverage-threshold` is checked against.
- File names and percentages are colored like Jest: green at 80% or more, yellow at 50% or more, red below.
- `Uncovered Line #s` is colored by how many lines are uncovered in total (not how many groups): yellow for 3 or fewer, red for more. So `12,16-17,20-21,24` is red (6 lines) and `5,15,21` is yellow (3 lines).

### Coverage Reporters

`--coverage-reporters` (or `COVERAGE_REPORTERS` in the config) picks the outputs, as a comma-separated list:

| Reporter    | Output                                                                  |
| ----------- | ----------------------------------------------------------------------- |
| `text`      | the console table above (the default)                                   |
| `lcov`      | `coverage/lcov.info`, for Codecov, Coveralls, genhtml and editors       |
| `cobertura` | `coverage/cobertura-coverage.xml`, for GitLab, Jenkins and Azure DevOps |

```bash
shest --coverage-reporters text,lcov                       # table on screen plus lcov.info
shest --coverage-reporters lcov,cobertura --coverage-directory build/cov
shest --coverage-reporters lcov --coverage-threshold 80    # files only, still fails under 80%
```

- Choosing `lcov` or `cobertura` turns coverage on, so `--coverage` is not needed.
- Without `text`, the console shows only the `Coverage: 73.68% (28/38 lines)` line, and the threshold still applies.
- The directory is created when missing (default `coverage`, set with `--coverage-directory` or `COVERAGE_DIRECTORY`).
- Both formats list each executable line as hit or not hit (`hits` is `1` or `0`, not an execution count). Branch data is not collected, so branch rates are `0`.

- Coverage is **line coverage** of the files your tests `source`. Test files, `shest` and `utils/` are excluded.
- A `DEBUG` trap records every executed line. Expect noticeably slower runs, so it is opt-in.
- Executable lines are detected heuristically: blank lines, comments, lone `}`/`fi`/`done`/`else`, function declaration lines, heredoc bodies and multi-line array bodies are not counted, and a command split with `\` counts once. Unusual layouts may be off by a line.
- A file that no test sources is not listed (it is not reported as 0%).

## Configuration

shest reads `shest.config.sh` from the current directory, or the file given with `--config <file>`. It is plain bash that sets variables, so it can use comments, arrays, variables and conditions. Every setting is optional.

```bash
# shest.config.sh
TEST_MATCH=("tests/**/*.test.sh")
TEST_PATH_IGNORE_PATTERNS=("/build/" "/dist/" "/node_modules/")
COVERAGE_PATH_IGNORE_PATTERNS=("/vendor/")
COVERAGE_THRESHOLD=80
BAIL=true
```

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `TEST_MATCH` | array | `(".")` | Paths, directories or globs to run when none is given on the command line |
| `TEST_PATH_IGNORE_PATTERNS` | array | `()` | Test files whose path contains any of these substrings are skipped |
| `COVERAGE` | `true`/`false` | `false` | Collect and print coverage |
| `COVERAGE_THRESHOLD` | integer | unset | Fail below this percentage; implies `COVERAGE=true` |
| `COVERAGE_PATH_IGNORE_PATTERNS` | array | `()` | Source files to leave out of the coverage report |
| `COVERAGE_REPORTERS` | array | `(text)` | Any of `text`, `lcov`, `cobertura`; the last two turn coverage on |
| `COVERAGE_DIRECTORY` | path | `coverage` | Where the `lcov` / `cobertura` files are written |
| `PARALLEL` | integer | `1` | Run up to this many test files at once |
| `TEST_TIMEOUT` | seconds | `0` | Kill tests that run longer; `0` means no limit |
| `BAIL` | `true`/`false` | `false` | Stop after the first failing file |
| `TIMING` | `true`/`false` | `false` | Show the time of each test |
| `REPORTER` | string | `default` | `default`, `tap` or `junit` |
| `OUTPUT_FILE` | path | unset | Write the report to a file instead of stdout |
| `NAME_FILTER` | regex | unset | Only run tests whose name matches |

### Precedence

Command-line options override the config file, and the config file overrides the defaults. A config file is read only when one exists, so shest works without it.

```bash
# shest.config.sh has BAIL=true and COVERAGE_THRESHOLD=80
shest --coverage-threshold 90      # 90 wins over 80
shest --config ci/shest.ci.sh      # use another file
```

### TEST_MATCH

Used only when you pass no path on the command line. Each entry can be a directory, a file or a glob, and `**` matches any depth. Quote the entries so shest expands them, not the shell.

```bash
TEST_MATCH=("tests")                                # every *.test.sh under tests/
TEST_MATCH=("tests/unit" "tests/integration")       # several directories
TEST_MATCH=("src/**/*.spec.sh")                     # recursive glob with a custom suffix
TEST_MATCH=("tests/**/*.test.sh" "scripts/smoke.sh") # globs and single files together
```

A directory runs only files named `*.test.sh`. Use a glob when your files are named differently, as in the `*.spec.sh` example.

### TEST_PATH_IGNORE_PATTERNS

Each entry is a **literal substring** of the file path, not a glob or a regex, like Jest's `testPathIgnorePatterns`. Paths are compared with a leading `/`, so `"/build/"` also matches `build/x.test.sh`.

```bash
TEST_PATH_IGNORE_PATTERNS=("/build/" "/dist/" "/node_modules/")   # skip whole directories
TEST_PATH_IGNORE_PATTERNS=("/fixtures/" ".slow.test.sh")          # a directory and a file suffix
TEST_PATH_IGNORE_PATTERNS=("failing")                             # any path containing "failing"
```

Ignored files are dropped before anything runs, so they do not count in `Test Files`.

### COVERAGE And COVERAGE_THRESHOLD

```bash
COVERAGE=true            # always print the coverage table
COVERAGE_THRESHOLD=80    # also fail (exit 1) below 80%; turns coverage on by itself
```

The threshold is an integer. Anything else (`80.5`, `high`) stops shest with an error. The check uses exact math on the total, so 79.99% fails a threshold of 80. Use `--coverage-threshold 0` on the command line to report coverage without ever failing.

### COVERAGE_PATH_IGNORE_PATTERNS

Same substring rule as above, applied to the absolute path of each source file. Test files (`*.test.sh`), shest itself and `utils/` are always excluded.

```bash
COVERAGE_PATH_IGNORE_PATTERNS=("/vendor/")                 # third-party code
COVERAGE_PATH_IGNORE_PATTERNS=("/generated/" "_legacy.sh") # a directory and a file suffix
```

### COVERAGE_REPORTERS And COVERAGE_DIRECTORY

```bash
COVERAGE_REPORTERS=(text lcov)              # table on screen plus coverage/lcov.info
COVERAGE_REPORTERS=(lcov cobertura)         # files only
COVERAGE_DIRECTORY=build/coverage           # where the files go
```

Any other value (`html`) stops shest with `unknown coverage reporter`.

### PARALLEL

```bash
PARALLEL=4                                  # four files at a time
PARALLEL=1                                  # sequential (the default)
```

Must be a positive integer. Output order and totals do not change; see [Parallel runs](#parallel-runs).

### TEST_TIMEOUT

```bash
TEST_TIMEOUT=30                             # every test gets 30 seconds
TEST_TIMEOUT=0.5                            # decimals are fine
TEST_TIMEOUT=0                              # no limit (the default)
```

A `# @timeout` decorator on a test overrides it. See [Timeouts](#timeouts).

### BAIL And TIMING

```bash
BAIL=true     # stop at the first failing file; the rest are reported as not run
TIMING=true   # print the duration after every test name
```

### REPORTER And OUTPUT_FILE

With `tap` or `junit` and no `OUTPUT_FILE`, the report goes to stdout and the human-readable output is hidden. With `OUTPUT_FILE`, the report goes to the file and the normal output stays on screen.

```bash
REPORTER=tap                      # TAP on stdout, for any TAP consumer
REPORTER=junit                    # JUnit XML on stdout
REPORTER=junit
OUTPUT_FILE=reports/junit.xml     # XML in the file, normal output on screen
```

Any other `REPORTER` value stops shest with `unknown REPORTER`.

### NAME_FILTER

An extended regular expression matched against test names. Tests that do not match are counted as skipped.

```bash
NAME_FILTER="divides"             # one word
NAME_FILTER="adds|divides"        # either one
NAME_FILTER="^validates "         # names that start with "validates "
```

### Config For CI

Because the file is bash, it can adapt to the environment:

```bash
# shest.config.sh
TEST_MATCH=("tests/**/*.test.sh")
TEST_PATH_IGNORE_PATTERNS=("/build/" "/node_modules/")
COVERAGE_PATH_IGNORE_PATTERNS=("/vendor/")

if [[ -n ${CI:-} ]]; then
  COVERAGE_THRESHOLD=80
  COVERAGE_REPORTERS=(text lcov)
  PARALLEL=4
  TEST_TIMEOUT=60
  BAIL=true
  REPORTER=junit
  OUTPUT_FILE=reports/junit.xml
fi
```

`shest --init` writes a commented `shest.config.sh` with every setting at its default (it refuses to overwrite an existing file). A sample lives in [shest.config.sh](shest.config.sh).

## Examples

The [examples](examples) directory contains runnable files:

| File                                                      | Shows                                          |
| --------------------------------------------------------- | ---------------------------------------------- |
| [sum.test.sh](examples/sum.test.sh)                       | basic tests, hooks                             |
| [matchers.test.sh](examples/matchers.test.sh)             | every matcher, `not`, and `@timeout`           |
| [failing.test.sh](examples/failing.test.sh)               | intentionally failing tests, including a `@timeout` kill |
| [skipping.test.sh](examples/skipping.test.sh)             | `@test.skip` and `@test.todo`                  |
| [only.test.sh](examples/only.test.sh)                     | `@test.only`                                   |
| [divide.test.sh](examples/divide.test.sh)                 | partial coverage (about 33%)                   |
| [string_utils.test.sh](examples/string_utils.test.sh)     | a fully covered source file (100%)             |
| [math_utils.test.sh](examples/math_utils.test.sh)         | a mostly covered source file (80%)             |
| [validators.test.sh](examples/validators.test.sh)         | a poorly covered source file (25%)             |
| [foo/bar/nested.test.sh](examples/foo/bar/nested.test.sh) | recursive `**` discovery                       |

## Development

```bash
make check   # bash -n, shellcheck and shfmt
make test    # shest's own tests, run by shest (tests/)
make fmt     # format with shfmt
```

### Tests

shest tests itself. The files in [tests](tests) run `shest` as a black box against throwaway projects and check its output and exit codes:

| File | Covers |
| --- | --- |
| [cli.test.sh](tests/cli.test.sh) | `--version`, `--help`, `--init`, bad options |
| [runner.test.sh](tests/runner.test.sh) | counting, skip / todo / only, filter, hooks, discovery, bail, isolation |
| [reporters.test.sh](tests/reporters.test.sh) | TAP, JUnit, `--output-file` |
| [coverage.test.sh](tests/coverage.test.sh) | the table, thresholds, ignore patterns, lcov and Cobertura |
| [config.test.sh](tests/config.test.sh) | `shest.config.sh`, overrides, validation |
| [features.test.sh](tests/features.test.sh) | timeouts, `--parallel`, `--list`, `--changed`, `--watch` |

[helpers.sh](tests/helpers.sh) creates the temporary projects. It writes fixture tests with `printf` rather than heredocs, because shest scans test files for `# @test` lines and a decorator inside a heredoc would be read as a real one.

ShellCheck settings live in `.shellcheckrc`, and `.editorconfig` sets the indentation `shfmt` uses (it also covers the extension-less `shest` script).

shest's own coverage cannot be measured by shest itself: the runner and `utils/` are excluded from coverage reports, so a run of `tests/` only reports on `tests/helpers.sh`.
