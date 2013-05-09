(define state
  (lambda (gl)
    (list
     (mat4.identity (mat4.create))
     (build-shader
      gl basic-vertex-shader basic-fragment-shader))))

(define state-tx (lambda (s) (list-ref s 0)))
(define state-shader (lambda (s) (list-ref s 1)))

(define state-clone
  (lambda (s)
    (list
     (mat4.create (state-tx s))
     (state-shader s)))) ;; todo: shader clone
