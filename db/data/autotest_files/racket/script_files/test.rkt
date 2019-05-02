#!/usr/bin/env racket
#lang racket

(require "submission.rkt")
(require (for-meta 1 "submission.rkt"))
(require (for-meta 1 rackunit))
(require (for-meta 1 racket/local))

(require syntax/macro-testing)
(require rackunit)

(define all-tests
  (test-suite
   "All tests"

   (test-suite
    "Task 1"
    (test-equal? "return" (return 1) (Just 1))
    (test-equal? "bind success" (bind (Just 1) (lambda (n) (safe-div 10 n))) (Just 10))
    (test-equal? "bind failure" (bind Nothing (lambda (n) (safe-div 10 n))) Nothing)

    (test-suite
     "Task 2"

     (test-equal?
      "do with a single expression"
      (phase1-eval
       (do-maybe
        (Just 1)))
      (Just 1))
     
     (test-equal?
      "Simple do expression (sample test)"
      (phase1-eval
       (do-maybe
        (x1 <- (parse-num "3"))
        (x2 <- (parse-num "8"))
        (return (+ x1 x2))))
      (Just 12))
     
     
     (test-equal?
      "Simple do expression with Nothing (sample test)"
      (phase1-eval
       (do-maybe
        (x1 <- (parse-num "3"))
        (x2 <- (parse-num "david"))
        (return (+ x1 x2))))
      Nothing)

     (test-equal?
      "do with several succcessful expressions"
      (phase1-eval
       (do-maybe
        (x1 <- (Just 4))
        (x2 <- (Just 10))
        (x3 <- (Just 100))
        (x4 <- (Just 4))
        (x5 <- (Just 6))
        (Just (+ x1 x2 x3 x4 x5))))
      (Just (+ 4 10 100 4 6)))

     (test-equal?
      "do with some failure expressions"
      (phase1-eval
       (do-maybe
        (x1 <- (Just 4))
        (x2 <- (Just 10))
        (x3 <- (Just 100))
        (x4 <- (Just 4))
        (x5 <- Nothing)
        (Just (+ x1 x2 x3 x4 x5))))
      Nothing)
     )

    (test-suite
     "Task 3"
     (test-equal?
      "Do notation without explicit bind (sample test)"
      (phase1-eval (do-maybe
                    (Just 1)
                    (Just 2)
                    (Just 3)
                    (Just 4)))
      (Just 4))

     (test-equal?
      "Do notation without explicit bind, with a Nothing (sample test)"
      (phase1-eval (do-maybe
                    (Just 1)
                    (Just 2)
                    Nothing
                    (Just 4)))
      Nothing)

     (test-equal?
      "Do notation mixing bind and standalone expressions"
      (phase1-eval (do-maybe
                    (x1 <- (Just 2))
                    (Just x1)
                    (x2 <- (Just 10))
                    (Just (+ x1 x2))))
      (Just 12))
     
     (test-equal?
      "Using let to bind a pure value (sample test)"
      (phase1-eval (do-maybe
                    (do-let x 50)
                    (do-let y 8)
                    (safe-div x y)))
      (Just 6))

     (test-equal?
      "Mixing let and bind (sample test)"
      (phase1-eval (do-maybe
                    (x <- (parse-num "3"))
                    (do-let y (+ x 10))
                    (return y)))
      (Just 13))

     (test-equal?
      "Mixing let and bind with failure (sample test)"
      (phase1-eval (do-maybe
                    (x <- (parse-num "david"))
                    (do-let y (+ x 10))
                    (return y)))
      Nothing)

     (test-equal?
      "Mixing let and standalone expressions (1)"
      (phase1-eval (do-maybe
                    (do-let x1 5)
                    (safe-div 10 x1)
                    (do-let y1 0)
                    (safe-div 10 y1)
                    (Just (+ x1 y1))))
      Nothing)
     ))))