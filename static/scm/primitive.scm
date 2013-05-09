(define primitive
  (lambda (size type vb)
    (list size type vb)))

(define primitive-size (lambda (p) (list-ref p 0)))
(define primitive-type (lambda (p) (list-ref p 1)))
(define primitive-vb (lambda (p) (list-ref p 2)))
(define primitive-modify-vb (lambda (p v) (list-replace p 2 v)))

(define build-primitive
  (lambda (gl size vbs)
    (let ((p (primitive size 0 vbs)))
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
  (lambda (p gl view camera local shader)
    (let ;; assumptions...
         ((pvb (buffer-vb (list-ref (primitive-vb p) 0)))
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

      (let ((tx (mat4.create)))
        (mat4.multiply camera local tx)
        (gl.uniformMatrix4fv shader.pMatrixUniform false view)
        (gl.uniformMatrix4fv shader.mvMatrixUniform false tx)
        (gl.drawArrays gl.TRIANGLES 0 pvb.numItems)))))
