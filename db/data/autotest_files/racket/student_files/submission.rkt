#lang racket #| CSC324 Winter 2018: Exercise 8 |#
#|
★ Before starting, please review the exercise guidelines at
https://www.cs.toronto.edu/~david/csc324/homework.html ★
|#
(provide Nothing Just
         safe-div parse-num
         bind return do-maybe)


;-------------------------------------------------------------------------------
; Task 1: Modeling Maybe in Racket
;-------------------------------------------------------------------------------
(define Nothing 'Nothing)
(define (Just x) (list 'Just x))


#|
(safe-div x y)
  x: int
  y: int

  If y equals 0, returns Nothing.
  Else returns (quotient x y)---wrapped in a Just, of course!
|#
(define (safe-div x y)
  (if (zero? y) 'Nothing
      (Just (quotient x y))
      ))

#|
(parse-num s)
  s: a string

  If an int can be parsed from s by using `string->number`, then
  succeed with that int. Else fail and return Nothing.
|#
(define (parse-num s)
  (if (string->number s)
      (Just (string->number s))
      'Nothing
      ))


; Equivalents of `return` and `(>>=)` for Maybe.
; (bind x f) should be equivalent to x >>= f in Haskell.
; Make sure you get the type signature for (>>=) correct from Haskell!
(define return Just)

(define (fromJust e)
  (if (list? e)
      (second e)
      (error "Tried to fromJust" e)))

(define (bind x f)
  (cond
    [(equal? x 'Nothing)  'Nothing]
    [(not (list? x))      (error "not a maybe" x)]
    [(not (procedure? f)) (error "not a procedure" f)]
    [else                 (f (fromJust x))]))

;-------------------------------------------------------------------------------
; Tasks 2 and 3: do notation in Racket
;-------------------------------------------------------------------------------

(define-syntax do-maybe
  (syntax-rules (do-let <-)

    [(do-maybe <bindings> ...  (do-let <id> <bind-expr>) <expr>)
     (do-maybe
       <bindings> ...
       (<id> <- (Just <bind-expr>))
       <expr>)]

    [(do-maybe <bindings> ... (<id> <- <bind-expr>) <expr>)
     (do-maybe
       <bindings> ...
       (bind <bind-expr> (lambda (<id>)
       <expr>)))]

    [(do-maybe <bindings> ... <bind-expr> <expr>)
     (do-maybe
       <bindings> ...
       (_ <- <bind-expr>)
       <expr>)]

    [(do-maybe <expr>)
       <expr>]
  )
)

