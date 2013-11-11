;; -*- mode: scheme; -*-
;; Planet Fluxus Copyright (C) 2013 Dave Griffiths
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(define (msg a)
  (display a)(newline))

(define (dbg a)
  (msg a) a)

(define zero?
  (lambda (n)
    (= n 0)))

(define (random n)
  (Math.floor (* (Math.random) n)))

(define (rndf) (Math.random))

;; replaced by underlying iterative version
;;(define foldl
;;  (lambda (fn v l)
;;    (cond
;;     ((null? l) v)
;;     (else (foldl fn (fn (car l) v) (cdr l))))))

(define map
  (lambda (fn l)
    (foldl
     (lambda (i r)
       (append r (list (fn i))))
     ()
     l)))

(define filter
  (lambda (fn l)
    (foldl
     (lambda (i r)
       (if (fn i) (append r (list i)) r))
     ()
     l)))

(define for-each
  (lambda (fn l)
    (foldl
     (lambda (i r)
       (fn i))
     ()
     l)
    #f))

(define index-map
  (lambda (fn l)
    (cadr (foldl
           (lambda (e r)
             (list
              (+ (car r) 1)
              (append (cadr r) (list (fn (car r) e)))))
           (list 0 ())
           l))))

(define index-for-each
  (lambda (fn l)
    (foldl
     (lambda (e r)
       (fn r e)
       (+ r 1))
     0
     l)))

(define display (lambda (str) (zc.to_page "output" str)))

(define newline (lambda () (zc.to_page "output" "\n")))

(define list-equal?
  (lambda (a b)
    (define _
      (lambda (a b)
        (cond
         ((null? a) #t)
         ((not (eq? (car a) (car b))) #f)
         (else (_ (cdr a) (cdr b))))))
    (if (eq? (length a) (length b))
        (_ a b) #f)))

;; replaced by js version
;;(define build-list
;;  (lambda (n fn)
;;    (define _
;;      (lambda (i)
;;        (cond
;;         ((eq? i (- n 1)) ())
;;         (else
;;          (cons (fn n) (_ (+ i 1) fn))))))
;;    (_ 0)))

(define print-list
  (lambda (l)
    (when (not (null? l))
          (console.log (car l))
          (print-list (cdr l)))))

(define reverse
  (lambda (l)
    (cond
     ((null? l) ())
     (else
      (append (reverse (cdr l)) (list (car l)))))))

(define (choose l)
  (list-ref l (random (length l))))

(define (delete-n l n)
  (if (eq? n 0)
      (cdr l)
      (append (list (car l)) (delete-n (cdr l) (- n 1)))))

(define shuffle
  (lambda (l)
    (if (< (length l) 2)
        l
        (let ((item (random (length l))))
          (cons (list-ref l item)
                (shuffle (delete-n l item)))))))

(define (crop l n)
  (cond
   ((null? l) ())
   ((zero? n) ())
   (else (cons (car l) (crop (cdr l) (- n 1))))))

(define factorial
  (lambda (n)
    (if (= n 0) 1
        (* n (factorial (- n 1))))))

;; convert code to text form
(define (scheme-txt v)
  (cond
    ((number? v) v)
    ((string? v) (string-append "'" v "'"))
    ((boolean? v) (if v "#t" "#f"))
    ((list? v)
     (cond
       ((null? v) "()")
       (else
        (list-txt v))))
   (else (msg (+ "scheme->txt, unsupported type for " v)))))

(define (list-txt l)
  (define (_ l s)
    (cond
     ((null? l) s)
     (else
      (_ (cdr l)
         (string-append
          s
          (if (not (eq? s "")) " " "")
          (scheme-txt (car l)))))))
  (string-append "(list " (_ l "") ")"))


(define a 0)

(define unit-test
  (lambda ()
    (display "unit tests running...")
    (set! a 10)
    (when (not (eq? 4 4)) (display "eq? failed"))
    (when (eq? 2 4) (display "eq?(2) failed"))
    (when (not (eq? (car (list 3 2 1)) 3)) (display "car failed"))
    (when (not (eq? (cadr (list 3 2 1)) 2)) (display "cadr failed"))
    (when (not (eq? (caddr (list 3 2 1)) 1)) (display "caddr failed"))

    (when (not (eq? (begin 1 2 3) 3)) (display "begin failed"))
    (when (not (eq? (list-ref (list 1 2 3) 2) 3)) (display "list-ref failed"))
    (when (not (list? (list 1 2 3))) (display "list? failed"))
    (when (list? 3) (display "list?(2) failed"))
    (when (null? (list 1 2 3)) (display "null? failed"))
    (when (not (null? (list))) (display "null?(2) failed"))
    (when (not (eq? (length (list 1 2 3 4)) 4)) (display "length failed"))
    (when (not (list-equal? (list 1 2 3 4) (list 1 2 3 4))) (display "list-equal failed"))
    (when (list-equal? (list 1 2 3 4) (list 1 4 3 4)) (display "list-equal(2) failed"))
    (when (not (list-equal? (append (list 1 2 3) (list 4 5 6)) (list 1 2 3 4 5 6)))
          (display "append failed"))
    (when (not (list-equal? (cdr (list 3 2 1)) (list 2 1))) (display "cdr failed"))
    (when (not (list-equal? (cons 1 (list 2 3)) (list 1 2 3))) (display "cons failed"))
    (when (not (eq? (foldl (lambda (a r) (+ a r)) 0 (list 1 2 1 1)) 5))
          (display "fold failed"))
    (when (not (list-equal? (map (lambda (i) (+ i 1)) (list 1 2 3 4)) (list 2 3 4 5)))
          (display "map failed"))
    (when (not (eq? (let ((a 1) (b 2) (c 3)) (+ a b c)) 6)) (display "let failed"))
    (when (not (eq? (let ((a 1) (b 2) (c 3)) (list 2 3) (+ a b c)) 6)) (display "let(2) failed"))
    (when (not (eq? a 10)) (display "set! failed"))
    (when (not (eq? (factorial 10) 3628800)) (display "factorial test failed"))
    (when (not (eq? (list-ref (list-replace (list 1 2 3) 2 4) 2) 4)) (display "list-replace failed"))
    (when (not (list-equal? (build-list 10 (lambda (n) n)) (list 0 1 2 3 4 5 6 7 8 9)))
          (display "build-list failed"))
    (when (eq? (not (+ 200 3)) 203) (display "+ failed"))
    (when (not (eq? (cond (#t (+ 3 2) (+ 100 1)) (else (+ 4 3))) 101)) (display "cond test failed"))
    (when (not (eq? (when #t (+ 3 2) (+ 100 1)) 101)) (display "when test failed"))
    ))

(display "base.scm starting up...")

(unit-test)
