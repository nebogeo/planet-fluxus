(define t 0)

(define crank
  (lambda ()
    (set! t (+ t 0.1))
    (requestAnimFrame crank)
    (set! r (renderer-render r t))))

(define startup
  (lambda ()
    (let ((canvas (document.getElementById "canvas")))
      (let ((gl (canvas.getContext "experimental-webgl")))
        (set! gl.viewportWidth canvas.width)
        (set! gl.viewportHeight canvas.height)
        (set! r (renderer gl))
        ;; set up camera transform
        (mat4.translate (renderer-camera r) (list 0 0 -10))
        (set! r (renderer-build-prefab r))
        (gl.clearColor 0.0 0.0 0.0 1.0)
        (gl.enable gl.DEPTH_TEST)
        (crank)
        ))))

(startup)
