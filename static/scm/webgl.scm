(define init-gl
  (lambda (canvas)
    (let ((gl (canvas.getContext "experimental-webgl")))
      (set! gl.viewportWidth canvas.width)
      (set! gl.viewportHeight canvas.height)
      gl)))

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
