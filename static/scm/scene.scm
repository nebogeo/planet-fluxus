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
