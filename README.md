# shest

`Shest` is an intuitive test runner for Bash scripts, inspired by Node.js Jest. The name Shest stands for **Sh**ell T**est**, it simplifies testing by providing a clear structure for writing, organizing, and executing shell script tests. With built-in support for assertions, `Shest` empowers developers to write reliable and maintainable Bash scripts effortlessly.

## Installation

To install `shest`, you can use the following command. It will check if the `shest` script already exists in `/usr/local/bin`. If not, it will download the script from the GitHub repository, place it in `/usr/local/bin`, and set the appropriate execution permissions.

### Installation Command:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aagamezl/shest/master/tools/install.sh)"
```

### What the Command Does

1. **Checks if `shest` Exists**:
   - Verifies if the `shest` script is already present in `/usr/local/bin`.
   - If it exists, the installation process is skipped, and a message confirms the script is already installed.

2. **Downloads the Script**:
   - If the script is not found, it fetches the latest version of `shest` from the GitHub repository using `curl`.

3. **Places the Script in `/usr/local/bin`**:
   - Saves the downloaded script to `/usr/local/bin/shest` to make it globally accessible.

4. **Sets Execution Permissions**:
   - Grants the script executable permissions using `chmod +x`.

5. **Displays the Installation Status**:
   - If the installation is successful, it displays a success message.
   - If the installation fails (e.g., due to permission issues), it notifies the user with an error message.


## Usage

To use the `shest` testing library in your shell scripts, you need to include the `shest` file at the beginning of your script using the `source` command. Below is an example of a simple test suite to demonstrate how to set up and run tests with `shest`:

```bash
#!/bin/bash

# Include the shest framework
source shest

# Define a test suite
describe "Example Test Suite" <<'TEST'
  test "Simple equality check" <<'SUITE'
    toBeEqual "1 + 1 equals 2" "$(echo $((1 + 1)))" "2"
  SUITE

  test "String contains check" <<'SUITE'
    toContain "Check substring" "Hello, World!" "World"
  SUITE
TEST

# Run the tests
pluralize_test
```

## Syntax

**Shest** tests are structured with describe blocks to group related test cases, and test blocks to define individual test suites. Each test block can contain multiple assertions, allowing you to validate your Bash script behavior with clarity and precision.

```bash
describe "Nouns ending in -ss, -sh, -ch, -x, -o" <<'TEST'
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
TEST
```
## Syntax Explanation

The provided Bash code is structured as a set of tests designed to check the pluralization of nouns according to certain rules. The code uses a testing framework with `describe`, `test`, and built-in `assertion` functions to assert the expected behavior. Here's an explanation of the code syntax:

1. **`describe` Block**: 
   - This block defines a group of related tests.
   - It begins with `describe` followed by a string that describes the test group and a heredoc (`<<'TEST'`) to encapsulate the test definitions.

2. **`test` Block**:
   - Inside the `describe` block, the `test` keyword is used to define individual test cases.
   - Each test case is described with a string (e.g., "We add -es to the noun that ends in -ss, -sh, -ch, -x") and uses a heredoc (`<<'SUITE'`) to group assertions.

3. **`Assertions`**: Use built-in functions to validate outcomes.
    - **`toBeEqual`**: Checks if the actual value equals the expected value.
    - **`toBeNotEqual`**: Checks if the actual value does not equal the expected value.
    - **`toBeTrue`**: Asserts that the actual value is `true`.
    - **`toBeFalse`**: Asserts that the actual value is `false`.
    - **`toContain`**: Verifies that a string or array contains a specific value.

4. **`Heredoc`**:
   - The heredoc syntax (`<<'TEST'` and `<<'SUITE'`) is used to include multi-line strings without interpreting variables or special characters within the string.
   - The block is terminated by the delimiter (`TEST` or `SUITE`).

## Result Report

The result report provides an overview of the outcome of running the test suite. It is structured as follows:

1. **Test Categories**:
   - The report groups tests into categories or suites based on different rules or functionalities being tested. Each category or suite typically contains several individual tests, and each test is described by a label or a title.

2. **Test Results**:
   - Each test is marked with either:
     - **✓ (Pass)**: The test passed, meaning the function or feature being tested behaved as expected.
     - **✗ (Fail)**: The test failed, indicating the actual behavior did not match the expected outcome. When a test fails, the report includes information on the expected value versus the actual received value to help diagnose the issue.

3. **Test Summary**:
   - **Test Suites**: A summary of the number of test suites (groups of tests). It shows how many suites passed and how many failed.
     - Example: "1 failed, 3 passed, 4 total" means 1 test suite failed and 3 passed out of 4 total test suites.
   - **Tests**: A summary of the individual tests. It shows how many individual tests passed and how many failed.
     - Example: "1 failed, 17 passed, 18 total" means 1 test failed and 17 passed out of 18 total tests.
   - **Time**: The total time taken to execute all the tests is displayed, showing the efficiency of the test run (e.g., "Time: 0.02 s").

This report helps to quickly assess the overall health of the software.

Example:
```bash
• Testing Assertions
  Testing toBeEqual
    ✓ toBeEqual: Passed
    ✓ toBeEqual: Passed

  Testing toBeNotEqual
    ✓ toBeNotEqual: Passed

  Testing toBeTrue
    ✓ toBeTrue: Passed

  Testing toBeFalse
    ✓ toBeFalse: Passed

  Testing toContain
    ✓ toContain: Passed
    ✓ toContain: Passed

Test Suites:    0 failed, 5 passed, 5 total
Tests:          0 failed, 7 passed, 7 total
Time:           0.01 s
```


## Roadmap

* **afterAll**: Runs a function after all the tests.
* **afterEach**: Runs a function after each one of the tests in this file completes.
* **beforeAll**: Runs a function before any of the tests in this file run.
* **beforeEach**: Runs a function before each of the tests in this file runs.
* **Test Report**: Improve test reports (including errors).
