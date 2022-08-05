source("submission.R")

test_that("positive integers can be added", {
  expect_equal(sum(5, 5), 10)
  expect_equal(sum(8, 2), 10)
  expect_equal(sum(1, 1), 2)
})

test_that("negative integers can be added", {
  expect_equal(sum(15, -5), 10)
  expect_equal(sum(-8, -6), -14)
  expect_equal(sum(-10, 20), 10)
})

test_that("this test raises an error", {
  my_error()
})
