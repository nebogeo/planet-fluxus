;; Planet Fluxus Copyright (C) 2013 Dave Griffiths
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

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


      (gl.uniform3fv shader.AmbientColour (vector 0.1 0.1 0.1))
      (gl.uniform3fv shader.DiffuseColour (vector 0.5 0.5 0.7))
      (gl.uniform3fv shader.SpecularColour (vector 1 1 1))
      (gl.uniform3fv shader.LightPos (vector 0 100 0))
      (gl.uniform1f shader.AmbientIntensity 1)
      (gl.uniform1f shader.DiffuseIntensity 1)
      (gl.uniform1f shader.SpecularIntensity 0)
      (gl.uniform1f shader.Roughness 1)

      (gl.uniformMatrix4fv shader.ViewMatrixUniform false view)
      (gl.uniformMatrix4fv shader.CameraMatrixUniform false camera)
      (gl.uniformMatrix4fv shader.LocalMatrixUniform false local)
      (let ((normal (mat4.create local)))
        (mat4.inverse normal)
        (gl.uniformMatrix4fv shader.NormalMatrixUniform false normal)
        (gl.drawArrays gl.TRIANGLES 0 pvb.numItems)))))
