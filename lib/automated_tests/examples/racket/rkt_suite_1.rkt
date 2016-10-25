#!/usr/bin/env racket

#lang racket
(require "code.rkt")


(define (print_result name in exp act marks status)
	 (printf "<test>
	    <name>~a</name>
	    <input>~a</input>
	    <expected>~a</expected>
	    <actual>~a</actual>
	    <marks_earned>~a</marks_earned>
	    <status>~a</status>
	    </test>\n"
	    name
	    in
	    exp
	    act
	    marks
	    status))
	    
(define (test1)
	(define name "gt pass")
	(define in "5 2")
	(define exp #t)
	(define max_marks 2)
	
	(define act (gt 5 2))
	(define marks (if (equal? act exp)
		2
		0))
	(define status (if (not (equal? marks 0))
		"pass"
		"fail"))
	(print_result name in exp act marks status))

(define (test2)
	(define name "lt pass")
	(define in "1 3")
	(define exp #t)
	(define max_marks 2)
	
	(define act (lt 1 3))
	(define marks (if (equal? act exp)
		2
		0))
	(define status (if (not (equal? marks 0))
		"pass"
		"fail"))
	(print_result name in exp act marks status))
	
(define (test3)
	(define name "lt fail")
	(define in "3 1")
	(define exp #t)
	(define max_marks 2)
	
	(define act (lt 3 1))
	(define marks (if (equal? act exp)
		2
		0))
	(define status (if (not (equal? marks 0))
		"pass"
		"fail"))
	(print_result name in exp act marks status))
	
(test1)
(test2)
(test3)
