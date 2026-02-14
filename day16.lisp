(defun make-heapq (&optional (test-fn #'<))
    ; cdr is test-fn
    ; car is tree
    ; => (('value . value) ('rank . rank) ('left . left-tree) ('right . right-tree))
    (cons nil test-fn))

(defun merge-trees (a b test-fn)
    (cond
        ((null a) b)
        ((null b) a)
        ((apply test-fn (list (cdr (assoc 'value b)) (cdr (assoc 'value a))))
            (merge-trees b a test-fn))
        (t (progn
            (rplacd (assoc 'right a) (merge-trees (cdr (assoc 'right a)) b test-fn))
            (if (null (cdr (assoc 'left a)))
                (progn
                    (rplacd (assoc 'left a) (cdr (assoc 'right a)))
                    (rplacd (assoc 'right a) nil)
                    (rplacd (assoc 'rank a) 1))
                (let ((a-left  (cdr (assoc 'left a)))
                      (a-right (cdr (assoc 'right a))))
                    (if (> (cdr (assoc 'rank a-right)) (cdr (assoc 'rank a-left)))
                        (progn
                            (rplacd (assoc 'left a) a-right)
                            (rplacd (assoc 'right a) a-left)))
                    (rplacd
                        (assoc 'rank a)
                        (+ 1 (cdr (assoc 'rank (cdr (assoc 'right a))))))))
            a))))
                        

(defun pop-heapq (heapq)
    ;; modifies heapq in place
    (let ((tree (car heapq))
          (test-fn (cdr heapq)))
        (setf (car heapq)
            (merge-trees
                (cdr (assoc 'left tree))
                (cdr (assoc 'right tree))
                test-fn))
        (cdr (assoc 'value tree))))

(defun push-heapq (value heapq)
    ;; modifies heapq in place
    (let ((tree (car heapq))
          (test-fn (cdr heapq)))
        (setf (car heapq)
            (merge-trees
                (list
                    (cons 'value value)
                    (cons 'rank 1)
                    (cons 'left nil)
                    (cons 'right nil))
                tree
                test-fn))))

;; Node is of the form ( loc . facing )
;; and loc is of the form ( r . c )

(defun node-on-wall-p (grid node)
    (char-equal #\# (gethash (cadr node) grid)))

(defun facing-to-drdc (facing)
    (case facing
        (face-east  '( 0 .  1))
        (face-north '(-1 .  0))
        (face-west  '( 0 . -1))
        (face-south '( 1 .  0))))

(defun rotate-face (facing)
    (case facing
        (face-east 'face-north)
        (face-north 'face-west)
        (face-west 'face-south)
        (face-south 'face-east)))

(defun get-adj-dijk (node)
    ; node is of the form (dist (row . col) . facing)
    (let ((row  (caadr node))
          (col  (cdadr node))
          (face (facing-to-drdc (cddr node)))
          (dist (car node)))
        (list
            ;; forward-facing node
            `(,(+    1 dist)
                (,(+ row (car face)) . ,(+ col (cdr face))) . ,(cddr node))
            `(,(+ 1000 dist)
                (,row . ,col) . ,(rotate-face (cddr node)))
            `(,(+ 1000 dist)
                (,row . ,col) . ,(rotate-face
                                    (rotate-face
                                        (rotate-face (cddr node))))))))

(defun insert-into (visited node)
    (let ((dist     (car node))
          (location (cdr node)))
        (setf (gethash location visited) dist)
        visited))

(defun dijk (grid xq visited)
    (loop
        finally (return visited)
        while (not (null (car xq)))
        do (let* ((current-node (pop-heapq xq))
                  (current-rcf  (cdr current-node)))
            (if (null (gethash current-rcf visited))
                (progn
                    (insert-into visited current-node)
                    (loop for adj in (remove-if
                            (lambda (n) (node-on-wall-p grid n))
                            (get-adj-dijk current-node))
                        do (push-heapq adj xq)))))))

(defun load-grid (fname)
    (let ((result (make-hash-table :test 'equal)))
        (with-open-file (fp fname)
            (loop for line = (read-line fp nil)
                for r from 0
                while line
                finally (return result)
                do (loop for glyph across line
                    for c from 0
                    do (progn
                        (cond
                            ((char-equal #\S glyph)
                                (setf (gethash 'start result) (cons r c)))
                            ((char-equal #\E glyph)
                                (setf (gethash 'end result) (cons r c))))
                        (setf (gethash (cons r c) result) glyph)))))))

(defun main ()
    (let ((grid (load-grid "input16.txt")))
        (let ((start-coord (gethash 'start grid))
              (end-coord (gethash 'end grid))
              (xq (make-heapq (lambda (a b) (< (car a) (car b)))))
              (dist-to-end nil))
            (loop for facing in (list 'face-east 'face-north 'face-west 'face-south)
                do (push-heapq (cons 0 (cons end-coord facing)) xq))
            (setf dist-to-end (dijk grid xq (make-hash-table :test 'equal)))
            (format t "~a~%" (gethash (cons start-coord 'face-east) dist-to-end)))))

(main)
