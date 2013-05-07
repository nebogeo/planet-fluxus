(define basic-fragment-shader
  "precision mediump float;\
   varying vec3 colour;\
   void main(void) {\
       gl_FragColor = vec4(colour,1.0);\
   }")

(define basic-vertex-shader
  "attribute vec3 p;\
   attribute vec3 n;\
   uniform mat4 uMVMatrix;\
   uniform mat4 uPMatrix;\
   varying vec3 colour;\
   void main(void) {\
       gl_Position = uPMatrix * uMVMatrix * vec4(p, 1.0);\
       vec4 ln = vec4(n, 1.0);\
       colour = vec3(0.5,0.5,1)*max(0.0,dot(vec4(0.85, 0.8, 0.75, 1.0),ln));\
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
    (let ((vb (gl.createBuffer)))
      (gl.bindBuffer gl.ARRAY_BUFFER vb)
      (gl.bufferData gl.ARRAY_BUFFER (js "new Float32Array(size)") gl.STATIC_DRAW)
      (set! vb.itemSize item-size)
      (set! vb.numItems (/ size item-size))
      vb)))

(define update-buffer!
  (lambda (gl vb vertices)
    (gl.bindBuffer gl.ARRAY_BUFFER vb)
    (gl.bufferData gl.ARRAY_BUFFER (js "new Float32Array(vertices)") gl.STATIC_DRAW)))

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

        (set! shader-program.vertexNormalAttribute
              (gl.getAttribLocation shader-program "n"))
        (gl.enableVertexAttribArray shader-program.vertexNormalAttribute)

        (set! shader-program.pMatrixUniform
              (gl.getUniformLocation shader-program "uPMatrix"))
        (set! shader-program.mvMatrixUniform
              (gl.getUniformLocation shader-program "uMVMatrix"))
        shader-program))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define buffer
  (lambda (gl name data item-size)
    (list name data
          ;; build empty buffers for testing
          (build-empty-buffer gl (length data) item-size))))

(define buffer-name (lambda (b) (list-ref b 0)))
(define buffer-data (lambda (b) (list-ref b 1)))
(define buffer-modify-data (lambda (b v) (list-replace b 1 v)))
(define buffer-vb (lambda (b) (list-ref b 2)))

(define buffer-update!
  (lambda (gl b)
    (update-buffer! gl (buffer-vb b) (buffer-data b))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define primitive
  (lambda (size type matrix vb shader)
    (list size type matrix vb shader)))

(define primitive-size (lambda (p) (list-ref p 0)))
(define primitive-type (lambda (p) (list-ref p 1)))
(define primitive-tx (lambda (p) (list-ref p 2)))
(define primitive-modify-tx (lambda (p v) (list-replace p 2 v)))
(define primitive-vb (lambda (p) (list-ref p 3)))
(define primitive-modify-vb (lambda (p v) (list-replace p 3 v)))
(define primitive-shader (lambda (p) (list-ref p 4)))

(define build-primitive
  (lambda (gl size vbs tx shader)
    (let ((p (primitive size 0 tx vbs shader)))
      (primitive-update-buffers! gl p)
      p)))

(define primitive-update-buffers!
  (lambda (gl p)
    (for-each
     (lambda (b)
       (buffer-update! gl b))
     (primitive-vb p))))

(define primitive-find-buffer
  (lambda (p name)
    (foldl
     (lambda (b r)
       (if (and (not r) (eq? (buffer-name b) name))
           b r))
     #f
     (primitive-vb p))))

(define primitive-modify-buffer
  (lambda (p name fn)
    (map
     (lambda (b)
       (if (eq? (buffer-name b) name)
           (fn b) b))
     (primitive-vb p))))

;(define primitive-add-vb
;  (lambda (p name item-size)
;    (let ((p (primitive-modify-vb
;              p (cons (buffer name
;                              (build-empty-buffer
;                               (primitive-size p)
;                               item-size))
;                      (primitive-vb p)))))
;;      (primitive-connect-vb-to-shader p name)
;      p)))

(define primitive-render
  (lambda (p gl view-matrix)
    (let ((shader (primitive-shader p))
          (pvb (buffer-vb (list-ref (primitive-vb p) 0)))
          (nvb (buffer-vb (list-ref (primitive-vb p) 1))))
      (gl.useProgram shader)
      (gl.bindBuffer gl.ARRAY_BUFFER pvb)
      (gl.vertexAttribPointer shader.vertexPositionAttribute
                              pvb.itemSize
                              gl.FLOAT false 0 0)
      (gl.bindBuffer gl.ARRAY_BUFFER nvb)
      (gl.vertexAttribPointer shader.vertexNormalAttribute
                              nvb.itemSize
                              gl.FLOAT false 0 0)

      (gl.uniformMatrix4fv shader.pMatrixUniform false view-matrix)
      (gl.uniformMatrix4fv shader.mvMatrixUniform false (primitive-tx p))
      (gl.drawArrays gl.TRIANGLES 0 pvb.numItems))))

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

;;;;;;;;;;;;;;;;;

(define vector
  (lambda (x y z)
    (list x y z)))

(define vx (lambda (v) (list-ref v 0)))
(define vy (lambda (v) (list-ref v 1)))
(define vz (lambda (v) (list-ref v 2)))


;;;;;;;;;;;;;;;;;

(define scene-node
  (lambda (id prim state children)
    (list id prim state children)))

(define scene-node-id (lambda (n) (list-ref n 0)))
(define scene-node-prim (lambda (n) (list-ref n 1)))
(define scene-node-state (lambda (n) (list-ref n 2)))
(define scene-node-children (lambda (n) (list-ref n 3)))
(define scene-node-modify-children (lambda (n v) (list-replace n 3 v)))

(define scene-node-add-child
  (lambda (n c)
    (scene-node-modify-children
     n (cons c (scene-node-children n)))))

(define scene-node-remove-child
  (lambda (n id)
    (scene-node-modify-children
     n (filter
        (lambda (c)
          (not (eq? (scene-node-id c) id)))
        (scene-node-children n)))))

;;;;;;;;;;;;;;;;;;;;;;;;;

(define state
  (lambda (gl)
    (list
     (mat4.identity (mat4.create))
     (build-shader
      gl basic-vertex-shader basic-fragment-shader)
     #f)))

(define state-tx (lambda (s) (list-ref s 0)))
(define state-shader (lambda (s) (list-ref s 1)))
(define state-prim (lambda (s) (list-ref s 2)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

(define unit-cube-vertices
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
    (let ((gl (renderer-gl _renderer)))
    (set! _renderer
          (renderer-add
           _renderer
           (build-primitive
            gl
            (length unit-cube-vertices)
            (list
             (buffer gl "p" unit-cube-vertices 3)
             (buffer gl "n" unit-cube-normals 3)
             )
            (mat4.create (state-tx _state))
            (build-shader
             gl basic-vertex-shader basic-fragment-shader)
            ;(state-shader _state)
            )))))

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
