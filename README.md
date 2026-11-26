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
- Skip tests (`@test.skip`), focus tests (`@test.only`) or filter by name (`--filter`)
- Line coverage report with an optional failing threshold (`--coverage`)
- Stop at the first failing file (`--bail`) and per-test timing (`--timing`)
- TAP and JUnit XML reports for CI (`--reporter`)
- Total run time, colored output, and a non-zero exit code on failure (CI friendly)
- Works on macOS bash 3.2 as well as bash 4/5
- One-line installer, upgrade and uninstall

## Installation

### One-line installer

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aagamezl/shest/master/bin/install.sh)"
```

or non-interactively (for CI and scripts):

```bash
curl -fsSL https://raw.githubusercontent.com/aagamezl/shest/master/bin/install.sh | sh -s -- --yes
```

The installer:

1. Downloads the repository (`curl` and `tar` are required).
2. Copies `shest.sh` and `utils/` into `~/.shest`.
3. Links `~/.local/bin/shest` to `~/.shest/shest.sh`, so you can run `shest` from anywhere.
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
./shest/shest.sh --help
```

`shest.sh` loads `utils/colors.sh` from its own directory, so keep the two together. A symlink to `shest.sh` works, since `shest` resolves it to find its files.

The examples below call `shest.sh`. If you installed with the installer, use `shest` instead.

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
./shest.sh --file sum.test.sh
```

```text
━━ sum.test.sh ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ adds 1 + 2 to equal 3
✓ adds 1 + 3 to not be equal 3

────────────────────────────────────────────────────────────────────
Test Files:  1 total, 1 passed, 0 failed
Tests:       2 total, 2 passed, 0 failed, 0 skipped
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
| `.modifier` | optional: `.skip` or `.only` (see below)                                        |
| `<name>`    | the display name for the report: free text, spaces and symbols allowed          |

| Decorator             | Effect                                                              |
| --------------------- | ------------------------------------------------------------------- |
| `# @test <name>`      | register the next function as a test                                |
| `# @test.skip <name>` | register it but do not run it (reported as skipped)                 |
| `# @test.only <name>` | run only the `.only` tests of this file; the others are skipped     |

Rules:

- The decorator must be **immediately followed by the function declaration**: no blank line, comment or other code in between. Otherwise `shest` stops with an error pointing at the file and line.
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

### Skipping and focusing

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

Shell arrays cannot be passed as a single argument, so join them with `printf` for `to_contain_item`. It matches whole items, so `milk` is not found inside `buttermilk`:

```bash
items=("diapers" "milk" "buttermilk")
expect "$(printf '%s\n' "${items[@]}")" to_contain_item "milk"
```

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
shest.sh [options] [path...]
```

| Option                         | Description                                                              |
| ------------------------------ | ------------------------------------------------------------------------ |
| `-p, --path <glob\|dir>...`    | Run test files matching the glob(s), or every `*.test.sh` in a directory |
| `-f, --file <file>...`         | Run the given test file(s)                                               |
| `-t, --filter <regex>`         | Run only tests whose name matches                                        |
| `--coverage`                   | Print a line coverage report                                             |
| `--coverage-threshold <n>`     | Fail when total coverage is below `n` percent (implies `--coverage`)     |
| `--bail`                       | Stop after the first failing file                                        |
| `--timing`                     | Show how long each test took                                             |
| `--reporter <name>`            | `default`, `tap` or `junit` (see [Reporters](#reporters))                |
| `--output-file <file>`         | Write the `tap` / `junit` report to a file instead of stdout             |
| `-v, --version`                | Show the version                                                         |
| `-h, --help`                   | Show help                                                                |

```bash
shest.sh                                   # every *.test.sh under the current directory
shest.sh --file sum.test.sh                # one file
shest.sh --path tests/                     # a directory, recursively
shest.sh --path 'tests/**/*.test.sh'       # a glob (quote it so shest expands it)
shest.sh --path a.test.sh b.test.sh        # several paths
shest.sh -t 'greater' --file matchers.test.sh
```

- Quote globs so shest expands them itself. `**` matches any number of directories on every bash version.
- Each file runs in its own process, so functions and variables never leak between files.
- The exit code is `1` when any test or file fails, a coverage threshold is missed, or no test files are found. Otherwise it is `0`.

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
Test Files:  10 total, 9 passed, 1 failed
Tests:       41 total, 28 passed, 10 failed, 3 skipped
Time:        0.73s
```

- `Test Files` counts files. A file fails when any of its tests fail or it cannot be loaded.
- `Tests` counts individual tests.
- `Time` is the total wall-clock time (sub-second precision with bash 5 or `perl`; whole seconds otherwise).

### Bail

`--bail` stops the run after the first file that fails. The files that were not run are counted and reported:

```text
Test Files:  2 total, 1 passed, 1 failed
Tests:       12 total, 2 passed, 10 failed, 0 skipped
Time:        0.17s

Bailed after the first failing file: 8 file(s) not run
```

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
shest.sh --reporter tap --path tests/                          # TAP on stdout
shest.sh --reporter junit --path tests/ > report.xml           # JUnit XML on stdout
shest.sh --reporter junit --output-file report.xml --path tests/
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
shest.sh --path 'examples/**/*.test.sh' --coverage
shest.sh --file examples/divide.test.sh --coverage-threshold 80
```

```text
--------------------------|---------|-------|-------------------
File                      | % Lines | Lines | Uncovered Line #s
--------------------------|---------|-------|-------------------
All files                 |   73.68 | 28/38 |
 examples/arithmetic.sh   |   83.33 |   5/6 | 15
 examples/math_utils.sh   |   80.00 | 12/15 | 5,15,21
 examples/string_utils.sh |  100.00 |   9/9 |
 examples/validators.sh   |   25.00 |   2/8 | 12,16-17,20-21,24
--------------------------|---------|-------|-------------------

Coverage: 73.68% (28/38 lines)
```

- The table follows the Jest layout: an `All files` row first, then one row per file, with the percentage of covered lines, `covered/total` lines and the uncovered line numbers (consecutive lines are shown as ranges).
- The total percentage is repeated under the table, and it is what `--coverage-threshold` is checked against.
- Percentages are colored like Jest: green at 80% or more, yellow at 50% or more, red below.

- Coverage is **line coverage** of the files your tests `source`. Test files, `shest.sh` and `utils/` are excluded.
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

### COVERAGE and COVERAGE_THRESHOLD

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

### BAIL and TIMING

```bash
BAIL=true     # stop at the first failing file; the rest are reported as not run
TIMING=true   # print the duration after every test name
```

### REPORTER and OUTPUT_FILE

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
  BAIL=true
  REPORTER=junit
  OUTPUT_FILE=reports/junit.xml
fi
```

A commented sample lives in [shest.config.sh](shest.config.sh).

## Examples

The [examples](examples) directory contains runnable files:

| File                                                      | Shows                                          |
| --------------------------------------------------------- | ---------------------------------------------- |
| [sum.test.sh](examples/sum.test.sh)                       | basic tests, hooks                             |
| [matchers.test.sh](examples/matchers.test.sh)             | every matcher, including the failing cases     |
| [failing.test.sh](examples/failing.test.sh)               | intentionally failing tests, to see the output |
| [skipping.test.sh](examples/skipping.test.sh)             | `@test.skip`                                   |
| [only.test.sh](examples/only.test.sh)                     | `@test.only`                                   |
| [divide.test.sh](examples/divide.test.sh)                 | partial coverage (about 33%)                   |
| [string_utils.test.sh](examples/string_utils.test.sh)     | a fully covered source file (100%)             |
| [math_utils.test.sh](examples/math_utils.test.sh)         | a mostly covered source file (80%)             |
| [validators.test.sh](examples/validators.test.sh)         | a poorly covered source file (25%)             |
| [foo/bar/nested.test.sh](examples/foo/bar/nested.test.sh) | recursive `**` discovery                       |

## Development

```bash
make check   # bash -n, shellcheck and shfmt
make fmt     # format with shfmt
```

ShellCheck settings live in `.shellcheckrc`.
