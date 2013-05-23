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

(js "var sin=Math.sin")
(js "var cos=Math.cos")

(define vector
  (lambda (x y z)
    (list x y z)))

(define vx (lambda (v) (list-ref v 0)))
(define vy (lambda (v) (list-ref v 1)))
(define vz (lambda (v) (list-ref v 2)))

(define vector-clone
  (lambda (v)
    (vector (vx v) (vy v) (vz v))))
