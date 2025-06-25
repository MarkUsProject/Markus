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

test_that("this test illustrates MarkUs metadata attributes", {
  expect_equal(1, 1)

  exp_signal(new_expectation(
    type = "success",
    message = "",
    markus_overall_comments = "This is an overall comment. Great job!",
    markus_tag = "good",
    markus_annotation = list(
      filename = "submission.R",
      content = "This function should not be used",
      line_start = 5,
      line_end = 5,
      column_start = 2,
      column_end = 6
    )
  ))
})
