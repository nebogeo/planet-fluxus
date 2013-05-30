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

(define r 0)

(define time
  (lambda ()
    (js "new Date().getTime()/1000;")))

 (define push
  (lambda ()
    (set! r (renderer-stack-dup r))))

(define pop
  (lambda ()
    (set! r (renderer-stack-pop r))))

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

(define (load-texture name)
  (load-texture-impl!
   (renderer-gl r)
   (+ "/static/textures/" name)))

(define (texture name)
  (set! r (renderer-modify-stack-top
           r
           (lambda (state)
             (state-modify-texture state name)))))

(define (colour col)
  (set! r (renderer-modify-stack-top
           r
           (lambda (state)
             (state-modify-colour state col)))))

(define every-frame-impl
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
