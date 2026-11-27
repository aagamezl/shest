# shellcheck shell=bash

# @test runs normally
test_runs() {
  expect 1 to_be 1
}

# @test.skip fails if it ever runs
test_skipped() {
  expect 1 to_be 2
}

# @test.skip also fails if it ever runs
test_skipped_too() {
  expect 1 to_be 2
}

# @test.todo handles empty input
# @test.todo reports an error for a negative number
