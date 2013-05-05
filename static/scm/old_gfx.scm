










(define initGL
  (lambda (canvas)
    (set! gl (canvas.getContext "experimental-webgl"))
    (set! gl.viewportWidth canvas.width)
    (set! gl.viewportHeight canvas.height)
    ))

(define getShader
  (lambda (gl type code)
    (let ((shader (gl.createShader type)))
      (gl.shaderSource shader code)
      (gl.compileShader shader)
      (if (not (gl.getShaderParameter shader gl.COMPILE_STATUS))
          (begin
            (alert (gl.getShaderInfoLog shader))
            #f)
          (begin
            (console.log "compiled shader")
            shader)))))

(define shaderProgram 0)

(define initShaders
  (lambda ()
    (let ((fragmentShader (getShader gl gl.FRAGMENT_SHADER
                                     "precision mediump float;\
                                      void main(void) {\
                                         gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);\
                                      }"))
          (vertexShader (getShader gl gl.VERTEX_SHADER
                                   "attribute vec3 aVertexPosition;\
                                    uniform mat4 uMVMatrix;\
                                    uniform mat4 uPMatrix;\
                                    void main(void) {\
                                       gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);\
                                    }")))
      (set! shaderProgram (gl.createProgram))
      (gl.attachShader shaderProgram vertexShader)
      (gl.attachShader shaderProgram fragmentShader)
      (gl.linkProgram shaderProgram)
      (when (not (gl.getProgramParameter shaderProgram gl.LINK_STATUS))
            (alert "Could not initialise shaders"))
      (gl.useProgram shaderProgram)
      (set! shaderProgram.vertexPositionAttribute (gl.getAttribLocation shaderProgram "aVertexPosition"))
      (gl.enableVertexAttribArray shaderProgram.vertexPositionAttribute)
      (set! shaderProgram.pMatrixUniform (gl.getUniformLocation shaderProgram "uPMatrix"))
      (set! shaderProgram.mvMatrixUniform (gl.getUniformLocation shaderProgram "uMVMatrix"))
    )))

(define mvMatrix (mat4.create))
(define pMatrix (mat4.create))

(define setMatrixUniforms
  (lambda ()
    (gl.uniformMatrix4fv shaderProgram.pMatrixUniform false pMatrix)
    (gl.uniformMatrix4fv shaderProgram.mvMatrixUniform false mvMatrix)))

(define triangleVertexPositionBuffer 0)
(define squareVertexPositionBuffer 0)

(define initBuffers
  (lambda ()
    (set! triangleVertexPositionBuffer (gl.createBuffer))
    (gl.bindBuffer gl.ARRAY_BUFFER triangleVertexPositionBuffer)

    (define vertices (list
                      0.0  1.0  0.0
                      -1.0 -1.0  0.0
                      1.0 -1.0  0.0
                      ))

    (gl.bufferData gl.ARRAY_BUFFER (js "new Float32Array(vertices)") gl.STATIC_DRAW)
    (set! triangleVertexPositionBuffer.itemSize 3)
    (set! triangleVertexPositionBuffer.numItems 3)
    (set! squareVertexPositionBuffer (gl.createBuffer))
    (gl.bindBuffer gl.ARRAY_BUFFER squareVertexPositionBuffer)
    (define vertices (list
                      1.0  1.0  0.0
                      -1.0  1.0  0.0
                      1.0 -1.0  0.0
                      -1.0 -1.0  0.0
                      ))
    (gl.bufferData gl.ARRAY_BUFFER (js "new Float32Array(vertices)") gl.STATIC_DRAW)
    (set! squareVertexPositionBuffer.itemSize 3)
    (set! squareVertexPositionBuffer.numItems 4)))

(define rTri 0)
(define rSquare 0)

(define drawScene
  (lambda (t)
    (gl.viewport 0 0 gl.viewportWidth gl.viewportHeight)
    (gl.clear (js "gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT"))
    (mat4.perspective 45 (/ gl.viewportWidth gl.viewportHeight) 0.1 100.0 pMatrix)
    (mat4.identity mvMatrix)

    (mat4.translate mvMatrix (list -1.5 0.0 -7.0))
    (mat4.rotate mvMatrix rTri (list 0.0 1 0.0))
    (gl.bindBuffer gl.ARRAY_BUFFER triangleVertexPositionBuffer)
    (gl.vertexAttribPointer shaderProgram.vertexPositionAttribute
                            triangleVertexPositionBuffer.itemSize
                            gl.FLOAT false 0 0)
    (setMatrixUniforms)
    (gl.drawArrays gl.TRIANGLES 0 triangleVertexPositionBuffer.numItems)


    ))

(define lastTime 0)

(define animate
  (lambda ()
    (set! timeNow (js "new Date().getTime()"))
    (when (not (eq? lastTime 0))
          (let ((elapsed (- timeNow lastTime)))
            (set! rTri (+ rTri (* 0.01 elapsed)))
            (set! rSquare (+ rSquare (/ (* 75 elapsed) 1000.0)))))
    (set! lastTime timeNow)))

(define tick
  (lambda ()
    (requestAnimFrame tick)
    (drawScene)
    (animate)))

(define _webGLStart
  (lambda ()
    (let ((canvas (document.getElementById "canvas")))
      (initGL canvas)
      (initShaders)
      (initBuffers)
      (gl.clearColor 1.0 0.0 0.0 1.0)
      (gl.enable gl.DEPTH_TEST)
      (tick))))
