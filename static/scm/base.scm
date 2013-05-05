(define zero?
  (lambda (n)
    (= n 0)))

(define map
  (lambda (fn l)
    (cond
     ((null? l) ())
     (else (cons (fn (car l)) (map fn (cdr l)))))))

(define foldl
  (lambda (fn v l)
    (cond
     ((null? l) v)
     (else (foldl fn (fn (car l) v) (cdr l))))))

(define display (lambda (str) (zc.to_page "output" str)))

(define newline (lambda () (zc.to_page "output" "\n")))

(define list-equal?
  (lambda (a b)
    (define _ (lambda (a b)
                (cond
                 ((null? a) #t)
                 ((not (eq? (car a) (car b))) #f)
                 (else (_ (cdr a) (cdr b))))))
    (if (eq? (length a) (length b))
        (_ a b) #f)))

(define build-list
  (lambda (n fn)
    (define _
      (lambda (i)
        (cond
         ((eq? i (- n 1)) ())
         (else
          (cons (fn n) (_ (+ i 1) fn))))))
    (_ 0)))

(define print-list
  (lambda (l)
    (when (not (null? l))
          (console.log (car l))
          (print-list (cdr l)))))

(define for-each
  (lambda (fn l)
    (cond
     ((null? l) #f)
     (else
      (begin
        (fn (car l))
        (for-each fn (cdr l)))))))


(define factorial
  (lambda (n)
    (if (= n 0) 1
        (* n (factorial (- n 1))))))

(define a 0)

(define unit-test
  (lambda ()
    (set! a 10)
    (and
     (list-equal? (list 1 2 3 4) (list 1 2 3 4))
     (not (list-equal? (list 1 2 3 4) (list 1 4 3 4)))
     (list-equal? (map (lambda (i) (+ i 1)) (list 1 2 3 4)) (list 2 3 4 5))
     (eq? (foldl (lambda (a r) (+ a r)) 0 (list 1 2 1 1)) 5)
     (eq? (let ((a 1) (b 2) (c 3)) (+ a b c)) 6)
     (eq? (let ((a 1) (b 2) (c 3)) (list 2 3) (+ a b c)) 6)
     (eq? a 10)
     (eq? (factorial 10) 3628800)
     (eq? (list-ref (list-replace (list 1 2 3) 2 4) 2) 4)
     (list-equal? (build-list 10 (lambda (n) n)) (list 1 2 3 4 5 6 7 8 9))
     )))

(display "base.scm starting up...")

(if (unit-test)
    (display "tests passed")
    (display "tests didn't pass!"))
