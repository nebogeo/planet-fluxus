(define r 0)

(define translate
  (lambda (v)
    (mat4.translate (renderer-top-tx r) v)))

(define rotate
  (lambda (v)
    (mat4.rotate (renderer-top-tx r) (* (vx v) 0.0174532925) (list 1 0 0))
    (mat4.rotate (renderer-top-tx r) (* (vy v) 0.0174532925) (list 0 1 0))
    (mat4.rotate (renderer-top-tx r) (* (vz v) 0.0174532925) (list 0 0 1))))

(define scale
  (lambda (v)
    (mat4.scale (renderer-top-tx r) v)))

(define every-frame
  (lambda (hook)
    (set! r (renderer-modify-hook r hook))))

(define draw-cube
  (lambda ()
    (set! r (renderer-immediate-add
             r (list-ref (renderer-prefab r) 0)))))

(define build-polygons
  (lambda (type count)
    (let ((gl (renderer-gl r)))
    (set! r
          (renderer-add
           r
           (build-primitive
            gl
            (length unit-cube-vertices)
            (list
             (buffer gl "p" unit-cube-vertices 3)
             (buffer gl "n" unit-cube-normals 3)
             )))))))
