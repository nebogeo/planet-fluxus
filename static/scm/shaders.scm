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
