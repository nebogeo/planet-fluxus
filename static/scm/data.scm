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

(define unit-cube-vertices
  (list
   -0.5  0.5 -0.5   0.5  0.5 -0.5  -0.5 -0.5 -0.5
    0.5 -0.5 -0.5   0.5  0.5 -0.5  -0.5 -0.5 -0.5
    0.5  0.5 -0.5   0.5  0.5  0.5   0.5 -0.5 -0.5
    0.5 -0.5  0.5   0.5  0.5  0.5   0.5 -0.5 -0.5
   -0.5  0.5  0.5   0.5  0.5  0.5  -0.5  0.5 -0.5
    0.5  0.5 -0.5   0.5  0.5  0.5  -0.5  0.5 -0.5
    0.5  0.5  0.5  -0.5  0.5  0.5   0.5 -0.5  0.5
   -0.5 -0.5  0.5  -0.5  0.5  0.5   0.5 -0.5  0.5
   -0.5  0.5  0.5  -0.5  0.5 -0.5  -0.5 -0.5  0.5
   -0.5 -0.5 -0.5  -0.5  0.5 -0.5  -0.5 -0.5  0.5
   -0.5 -0.5 -0.5   0.5 -0.5 -0.5  -0.5 -0.5  0.5
    0.5 -0.5  0.5   0.5 -0.5 -0.5  -0.5 -0.5  0.5))

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

(define unit-cube-texcoords
  (list
    0  1  0   1  1  0   0  0  0
    1  0  0   1  1  0   0  0  0
    0  1  0   1  1  0   0  0  0
    1  0  0   1  1  0   0  0  0
    0  1  0   1  1  0   0  0  0
    1  0  0   1  1  0   0  0  0
    0  1  0   1  1  0   0  0  0
    1  0  0   1  1  0   0  0  0
    0  1  0   1  1  0   0  0  0
    1  0  0   1  1  0   0  0  0
    0  1  0   1  1  0   0  0  0
    1  0  0   1  1  0   0  0  0))
