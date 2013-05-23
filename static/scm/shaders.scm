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

(define blinn-vertex-shader "\
precision mediump float;\
uniform vec3 LightPos;\
varying vec3 N;\
varying vec3 P;\
varying vec3 V;\
varying vec3 L;\
uniform mat4 ViewMatrix;\
uniform mat4 CameraMatrix;\
uniform mat4 LocalMatrix;\
uniform mat4 NormalMatrix;\
attribute vec3 p;\
attribute vec3 n;\
void main()\
{\
    mat4 ModelViewMatrix = ViewMatrix * CameraMatrix * LocalMatrix;\
    N = normalize(vec4(n,1.0)).xyz;\
    P = p.xyz;\
    V = -vec3(ModelViewMatrix*vec4(p,1.0));\
	L = vec3(ModelViewMatrix*vec4((LightPos-p),1));\
    gl_Position = ModelViewMatrix * vec4(p,1);\
}")

(define blinn-fragment-shader "\
precision mediump float;\
uniform vec3 AmbientColour;\
uniform vec3 DiffuseColour;\
uniform vec3 SpecularColour;\
uniform float AmbientIntensity;\
uniform float DiffuseIntensity;\
uniform float SpecularIntensity;\
uniform float Roughness;\
varying vec3 N;\
varying vec3 P;\
varying vec3 V;\
varying vec3 L;\
void main()\
{ \
    vec3 l = normalize(L);\
    vec3 n = normalize(N);\
    vec3 v = normalize(V);\
    vec3 h = normalize(l+v);\
    float diffuse = dot(l,n);\
    float specular = pow(max(0.0,dot(n,h)),1.0/Roughness);\
    gl_FragColor = vec4(AmbientColour*AmbientIntensity + \
                        DiffuseColour*diffuse*DiffuseIntensity +\
                        SpecularColour*specular*SpecularIntensity,1);\
}")


(define basic-fragment-shader
  "precision mediump float;\
   varying vec3 colour;\
   void main(void) {\
       gl_FragColor = vec4(colour,1.0);\
   }")

(define basic-vertex-shader
  "attribute vec3 p;\
   attribute vec3 n;\
   uniform mat4 ViewMatrix;\
   uniform mat4 CameraMatrix;\
   uniform mat4 LocalMatrix;\
   uniform mat4 NormalMatrix;\
   varying vec3 colour;\
   void main(void) {\
       gl_Position = (ViewMatrix * CameraMatrix * LocalMatrix) * vec4(p, 1.0);\
       vec4 ln = vec4(n, 1.0);\
       colour = vec3(0.5,0.5,1)*max(0.0,dot(vec4(0.85, 0.8, 0.75, 1.0),ln));\
   }")
