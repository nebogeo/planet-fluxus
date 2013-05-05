;; scheme webgl renderer

(define basic-fragment-shader
  "precision mediump float;\
   void main(void) {\
       gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);\
   }")

(define basic-vertex-shader
  "attribute vec3 p;\
   uniform mat4 uMVMatrix;\
   uniform mat4 uPMatrix;\
   void main(void) {\
       gl_Position = uPMatrix * uMVMatrix * vec4(p, 1.0);\
   }")

;; vertex buffer primitives

(define build-buffer
  (lambda (gl vertices item-size)
    (let ((vb (gl.createBuffer)))
      (gl.bindBuffer gl.ARRAY_BUFFER vb)
      (gl.bufferData gl.ARRAY_BUFFER (js "new Float32Array(vertices)") gl.STATIC_DRAW)
      (set! vb.itemSize item-size)
      (set! vb.numItems (/ (length vertices) item-size))
      vb)))

(define build-empty-buffer
  (lambda (gl size item-size)
    (let ((vertices (build-list (* size item-size) (lambda (n) 0))))
      (build-buffer gl vertices item-size))))

;; shaders

(define compile-shader
  (lambda (gl type code)
    (let ((shader (gl.createShader type)))
      (gl.shaderSource shader code)
      (gl.compileShader shader)
      (if (not (gl.getShaderParameter shader gl.COMPILE_STATUS))
          (begin
            (alert (gl.getShaderInfoLog shader))
            #f)
          shader))))

(define build-shader
  (lambda (gl vert frag)
    (let ((fragment-shader (compile-shader gl gl.FRAGMENT_SHADER frag))
          (vertex-shader (compile-shader gl gl.VERTEX_SHADER vert)))
      (let ((shader-program (gl.createProgram)))
        (gl.attachShader shader-program vertex-shader)
        (gl.attachShader shader-program fragment-shader)
        (gl.linkProgram shader-program)
        (when (not (gl.getProgramParameter shader-program gl.LINK_STATUS))
              (alert "could not initialise shaders"))
        (gl.useProgram shader-program)
        (set! shader-program.vertexPositionAttribute
              (gl.getAttribLocation shader-program "p"))
        (gl.enableVertexAttribArray shader-program.vertexPositionAttribute)
        (set! shader-program.pMatrixUniform
              (gl.getUniformLocation shader-program "uPMatrix"))
        (set! shader-program.mvMatrixUniform
              (gl.getUniformLocation shader-program "uMVMatrix"))
        shader-program))))

;; structures for renderer

(define buffer (lambda (name vb) (list name vb)))
(define buffer-name (lambda (b) (list-ref b 0)))
(define buffer-vb (lambda (b) (list-ref b 1)))

(define primitive
  (lambda (id size type matrix vb shader)
    (list id size type matrix vb shader)))

(define primitive-id (lambda (p) (list-ref p 0)))
(define primitive-size (lambda (p) (list-ref p 1)))
(define primitive-type (lambda (p) (list-ref p 2)))
(define primitive-tx (lambda (p) (list-ref p 3)))
(define primitive-modify-tx (lambda (p v) (list-replace p 3 v)))
(define primitive-vb (lambda (p) (list-ref p 4)))
(define primitive-modify-vb (lambda (p v) (list-replace p 4 v)))
(define primitive-shader (lambda (p) (list-ref p 5)))

;(define primitive-connect-vb-to-shader
;  (lambda (p name)
;    (let ((shader-program (primitive-shader p)))
;      (cond
;       ((eq? name "p")
;        (set! shader-program.vertexPositionAttribute
;              (gl.getAttribLocation shader-program name))
;        (gl.enableVertexAttribArray
;         shader-program.vertexPositionAttribute))))))
;
;(define primitive-add-vb
;  (lambda (p name item-size)
;    (let ((p (primitive-modify-vb
;              p (cons (buffer name
;                              (build-empty-buffer
;                               (primitive-size p)
;                               item-size))))))
;      (primitive-connect-vb-to-shader p name)
;      p)))

(define build-primitive
  (lambda (gl id tx vertices shader)
    (primitive
     id 0 0 tx
     (build-buffer gl vertices)
     shader)))

(define primitive-render
  (lambda (p gl view-matrix)
    (let ((shader (primitive-shader p))
          (vb (primitive-vb p)))
      (gl.bindBuffer gl.ARRAY_BUFFER vb)
      (gl.vertexAttribPointer shader.vertexPositionAttribute
                              vb.itemSize
                              gl.FLOAT false 0 0)
      (gl.uniformMatrix4fv shader.pMatrixUniform false view-matrix)
      (gl.uniformMatrix4fv shader.mvMatrixUniform false (primitive-tx p))
      (gl.drawArrays gl.TRIANGLES 0 vb.numItems))))

(define renderer
  (lambda (gl) (list gl () (mat4.identity (mat4.create)))))

(define renderer-gl (lambda (r) (list-ref r 0)))
(define renderer-list (lambda (r) (list-ref r 1)))
(define renderer-modify-list (lambda (r v) (list-replace r 1 v)))
(define renderer-view (lambda (r) (list-ref r 2)))

(define renderer-add
  (lambda (r p)
    (renderer-modify-list r (cons p (renderer-list r)))))

(define init-gl
  (lambda (canvas)
    (let ((gl (canvas.getContext "experimental-webgl")))
      (set! gl.viewportWidth canvas.width)
      (set! gl.viewportHeight canvas.height)
      gl)))

(define render
  (lambda (renderer t)
    (let ((gl (renderer-gl renderer)))
      (gl.viewport 0 0 gl.viewportWidth gl.viewportHeight)
      (gl.clear (js "gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT"))
      (mat4.perspective 45 (/ gl.viewportWidth gl.viewportHeight) 0.1 100.0
                        (renderer-view renderer))


      (for-each
       (lambda (p)
         (mat4.rotate (primitive-tx p) 0.1 (list 0.5 0.5 0))

         (primitive-render
          p gl (renderer-view renderer)))
       (renderer-list renderer)))))

(define vector
  (lambda (x y z)
    (list x y z)))

(define vx (lambda (v) (list-ref v 0)))
(define vy (lambda (v) (list-ref v 1)))
(define vz (lambda (v) (list-ref v 2)))

(define state
  (lambda (gl)
    (list
     (mat4.identity (mat4.create))
     (build-shader
      gl basic-vertex-shader basic-fragment-shader))))

(define state-tx (lambda (s) (list-ref s 0)))
(define state-shader (lambda (s) (list-ref s 1)))

(define _renderer 0)
(define _state 0)

(define translate
  (lambda (v)
    (mat4.translate (state-tx _state) v)))

(define rotate
  (lambda (v)
    (mat4.rotate (state-tx _state) (* (vx v) 0.0174532925) (list 1 0 0))
    (mat4.rotate (state-tx _state) (* (vy v) 0.0174532925) (list 0 1 0))
    (mat4.rotate (state-tx _state) (* (vz v) 0.0174532925) (list 0 0 1))))

(define scale
  (lambda (v)
    (mat4.scale (state-tx _state) v)))

(define unit-cube
  (list
   -1  1 -1   1  1 -1  -1 -1 -1
    1 -1 -1   1  1 -1  -1 -1 -1
    1  1 -1   1  1  1   1 -1 -1
    1 -1  1   1  1  1   1 -1 -1
   -1  1  1   1  1  1  -1  1 -1
    1  1 -1   1  1  1  -1  1 -1
    1  1  1  -1  1  1   1 -1  1
   -1 -1  1  -1  1  1   1 -1  1
   -1  1  1  -1  1 -1  -1 -1  1
   -1 -1 -1  -1  1 -1  -1 -1  1
   -1 -1 -1   1 -1 -1  -1 -1  1
    1 -1  1   1 -1 -1  -1 -1  1))

(define unit-cube-normals
  (list
    0  0 -1   0  0 -1   0  0 -1
    0  0 -1   0  0 -1   0  0 -1
    1  0  0   1  0  0   1  0  0
    1  0  0   1  0  0   1  0  0
    0  1  0   0  1  0   0  1  0
    0  1  0   0  1  0   0  1  0
    0  0  1   0  0  1   0  0  1
    0  0  1   0  0  1   0  0  1
   -1  0  0  -1  0  0  -1  0  0
   -1  0  0  -1  0  0  -1  0  0
    0 -1  0   0 -1  0   0 -1  0
    0 -1  0   0 -1  0   0 -1  0))



(define build-polygons
  (lambda (type count)
    (set! _renderer
          (renderer-add
           _renderer
           (build-primitive
            (renderer-gl _renderer)
            0
            (mat4.create (state-tx _state))
            unit-cube
            (state-shader _state))))))

(define t 0)

(define crank
  (lambda ()
    (set! t (+ t 0.1))
    (requestAnimFrame crank)
    (render _renderer t)))

(define startup
  (lambda ()
    (let ((canvas (document.getElementById "canvas")))
      (let ((gl (canvas.getContext "experimental-webgl")))
        (set! gl.viewportWidth canvas.width)
        (set! gl.viewportHeight canvas.height)
        (set! _renderer (renderer gl))
        (set! _state (state gl))
        (gl.clearColor 0.0 0.0 0.0 1.0)
        (gl.enable gl.DEPTH_TEST)
        (crank)))))

(startup)
