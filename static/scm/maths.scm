(define vector
  (lambda (x y z)
    (list x y z)))

(define vx (lambda (v) (list-ref v 0)))
(define vy (lambda (v) (list-ref v 1)))
(define vz (lambda (v) (list-ref v 2)))
