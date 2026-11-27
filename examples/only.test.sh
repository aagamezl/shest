# shellcheck shell=bash

# @test not run because another test is .only
test_not_run() {
  expect 1 to_be 2
}

# @test.only the only one that runs
test_only() {
  expect 1 to_be 1
}
