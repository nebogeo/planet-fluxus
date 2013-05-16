(define state
  (lambda (gl)
    (list
     (mat4.identity (mat4.create))
     (build-shader
      gl
      blinn-vertex-shader
      blinn-fragment-shader
      )
     (vector 1 1 1))))

(define state-tx (lambda (s) (list-ref s 0)))
(define state-shader (lambda (s) (list-ref s 1)))
(define state-colour (lambda (s) (list-ref s 2)))

(define state-clone
  (lambda (s)
    (list
     (mat4.create (state-tx s))
     (state-shader s) ;; todo: shader clone
     (vector-clone (state-colour s)))))
