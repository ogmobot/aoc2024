(declaim (optimize (speed 3) (debug 0) (safety 0)))

(defun make-heapq (&optional (test-fn #'<))
    ; cdr is test-fn
    ; car is tree
    ; => (('value . value) ('rank . rank) ('left . left-tree) ('right . right-tree))
    ; or
    ; => #(value rank left-tree right-tree)
    (cons nil test-fn))

(defun hq-tree-get (tree key)
    ; (cdr (assoc key tree)))
    (aref tree (ecase key (value 0) (rank 1) (left 2) (right 3))))

(defun hq-tree-set (tree key val)
    ; (rplacd (assoc key tree) val))
    (setf (aref tree (ecase key (value 0) (rank 1) (left 2) (right 3))) val))

(defun hq-tree-new (value)
    ; (list (cons 'value value) (cons 'rank 1) (cons 'left nil) (cons 'right nil)))
    (vector value 1 nil nil))

(defun merge-trees (a b test-fn)
    (cond
        ((null a) b)
        ((null b) a)
        ((apply test-fn (list (hq-tree-get b 'value) (hq-tree-get a 'value)))
            (merge-trees b a test-fn))
        (t (progn
            (hq-tree-set a 'right (merge-trees (hq-tree-get a 'right) b test-fn))
            (if (null (hq-tree-get a 'left))
                (progn
                    (hq-tree-set a 'left (hq-tree-get a 'right))
                    (hq-tree-set a 'right nil)
                    (hq-tree-set a 'rank 1))
                (let ((a-left (hq-tree-get a 'left))
                      (a-right (hq-tree-get a 'right)))
                    (if (> (hq-tree-get a-right 'rank) (hq-tree-get a-left 'rank))
                        (progn
                            (hq-tree-set a 'left a-right)
                            (hq-tree-set a 'right a-left)))
                    (hq-tree-set a 'rank
                        (+ 1 (hq-tree-get (hq-tree-get a 'right) 'rank)))))
            a))))

(defun pop-heapq (heapq)
    ;; modifies heapq in place
    (let ((tree (car heapq))
          (test-fn (cdr heapq)))
        (setf (car heapq)
            (merge-trees
                (hq-tree-get tree 'left)
                (hq-tree-get tree 'right)
                test-fn))
        (hq-tree-get tree 'value)))

(defun push-heapq (value heapq)
    ;; modifies heapq in place
    (let ((tree (car heapq))
          (test-fn (cdr heapq)))
        (setf (car heapq)
            (merge-trees
                (hq-tree-new value)
                tree
                test-fn))))

;; Node is of the form ( dist loc . facing )
;; and loc is of the form ( r . c )

(defun node-on-wall-p (grid node)
    (char-equal #\# (gethash (cadr node) grid)))

(defun add-facing (facing coord)
    (let ((row (car coord))
          (col (cdr coord)))
        (ecase facing
            (face-east  (cons row       (+ col 1)))
            (face-north (cons (- row 1) col))
            (face-west  (cons row       (- col 1)))
            (face-south (cons (+ row 1) col)))))

(defun rotate-face (facing)
    (ecase facing
        (face-east 'face-north)
        (face-north 'face-west)
        (face-west 'face-south)
        (face-south 'face-east)))

(defun get-adj (node)
    ;; node is of the form (dist (row . col) . facing)
    (let ((pos    (cadr node))
          (facing (cddr node))
          (dist   (car node)))
        (list
            (cons (+    1 dist) (cons (add-facing facing pos) facing))
            (cons (+ 1000 dist) (cons pos (rotate-face facing)))
            (cons (+ 1000 dist) (cons pos (rotate-face
                                          (rotate-face
                                          (rotate-face facing))))))))

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
                            (get-adj current-node))
                        do (push-heapq adj xq)))))))

(defun find-optimal-tiles (grid min-dist dist-to-start dist-to-end)
    (loop for coord being the hash-keys of grid
        when (and
            (not (eq coord 'start))
            (not (eq coord 'end))
            (char-not-equal (gethash coord grid) #\#)
            (= min-dist (apply #'min
                (mapcar
                    (lambda (facing)
                        (+
                            (gethash (cons coord facing) dist-to-end)
                            (gethash
                                (cons coord (rotate-face (rotate-face facing)))
                                dist-to-start)))
                    (list 'face-east 'face-north 'face-west 'face-south)))))
        collect coord))

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

(defun main (fname)
    (let ((grid (load-grid fname)))
    (let ((start-coord (gethash 'start grid))
          (end-coord (gethash 'end grid))
          (xq (make-heapq (lambda (a b) (< (car a) (car b)))))
          (dist-to-end nil)
          (dist-to-start nil))
        ;; Calculate the distance from every point to the end
        (loop for facing in (list 'face-east 'face-north 'face-west 'face-south)
            do (push-heapq (cons 0 (cons end-coord facing)) xq))
        (setf dist-to-end (dijk grid xq (make-hash-table :test 'equal))) ; empties xq
        ;; Calculate the distance from every point to the start
        (push-heapq (cons 0 (cons start-coord 'face-east)) xq)
        (setf dist-to-start (dijk grid xq (make-hash-table :test 'equal)))

        (let ((min-dist (gethash (cons start-coord 'face-west) dist-to-end)))
            (format t "~a~%" min-dist)
            (format t "~a~%"
                (length (find-optimal-tiles grid min-dist dist-to-start dist-to-end)))))))

(main "input16.txt")
