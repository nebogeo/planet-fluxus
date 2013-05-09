(define renderer
  (lambda (gl)
    (list
     gl
     ()
     (mat4.identity (mat4.create))
     (mat4.identity (mat4.create))
     (list (state gl))
     ()
     #f
     ())))

(define renderer-gl (lambda (r) (list-ref r 0)))
(define renderer-list (lambda (r) (list-ref r 1)))
(define renderer-modify-list (lambda (r v) (list-replace r 1 v)))
(define renderer-view (lambda (r) (list-ref r 2)))
(define renderer-camera (lambda (r) (list-ref r 3)))
(define renderer-stack (lambda (r) (list-ref r 4)))
(define renderer-modify-stack (lambda (r v) (list-replace r 4 v)))
(define renderer-immediate-prims (lambda (r) (list-ref r 5)))
(define renderer-modify-immediate-prims (lambda (r v) (list-replace r 5 v)))
(define renderer-hook (lambda (r) (list-ref r 6)))
(define renderer-modify-hook (lambda (r v) (list-replace r 6 v)))
(define renderer-prefab (lambda (r) (list-ref r 7)))
(define renderer-modify-prefab (lambda (r v) (list-replace r 7 v)))

(define renderer-add
  (lambda (r p)
    (renderer-modify-list r (cons p (renderer-list r)))))

(define renderer-stack-dup
  (lambda (r)
    (renderer-modify-stack
     r (cons (state-clone (car (renderer-stack r)))
            (renderer-stack r)))))

(define renderer-stack-pop
  (lambda (r)
    (renderer-modify-stack
     r (cdr (renderer-stack r)))))

(define renderer-stack-top
  (lambda (r)
    (car (renderer-stack r))))

(define renderer-top-tx
  (lambda (r)
    (state-tx (renderer-stack-top r))))

(define renderer-immediate-add
  (lambda (r p)
    (renderer-modify-immediate-prims
     r (cons
        ;; state, and a primitive to render in
        (list (state-clone (renderer-stack-top r)) p)
        (renderer-immediate-prims r)))))

(define renderer-immediate-clear
  (lambda (r)
    (renderer-modify-immediate-prims r ())))

(define renderer-render
  (lambda (r t)
    (let ((gl (renderer-gl r))
          (hook (renderer-hook r)))
      (gl.viewport 0 0 gl.viewportWidth gl.viewportHeight)
      (gl.clear (js "gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT"))
      (mat4.perspective 45 (/ gl.viewportWidth gl.viewportHeight) 0.1 100.0
                        (renderer-view r))

      (when hook (hook))

      ;; immediate mode
      (for-each
       (lambda (p)
         (let ((state (car p))
               (prim (cadr p)))
           (primitive-render prim gl
                             (renderer-view r)
                             (renderer-camera r)
                             (state-tx state)
                             (state-shader state)
                             )))
       (renderer-immediate-prims r))

      ;; retained mode
;      (for-each
;       (lambda (p)
;         (primitive-render
;          p gl (renderer-camera r) (renderer-view r)))
;       (renderer-list r))

      (renderer-immediate-clear r))))

(define renderer-build-prefab
  (lambda (r)
    (let ((gl (renderer-gl r)))
      (renderer-modify-prefab
       r
       (list
        (build-primitive
         gl
         (length unit-cube-vertices)
         (list
          (buffer gl "p" unit-cube-vertices 3)
          (buffer gl "n" unit-cube-normals 3)
          )))))))
