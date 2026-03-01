(require 'srfi-1) ; list procecdures
(require 'srfi-69) ; hash tables

(define (get-adj coord)
    (let ((row (car coord))
          (col (cdr coord)))
        (list
            (cons (+ row 1) col)
            (cons (- row 1) col)
            (cons row (+ col 1))
            (cons row (- col 1)))))

(define (dijk grid xq distances)
    ;; recursive function
    ;; grid is a hash table
    ;; start-point is a cons pair
    (if (xq:isEmpty)
        distances
        (let ((current (xq:poll)))
            (if (hash-table-exists? distances current)
                (dijk grid xq distances)
                (begin
                    (hash-table-set! distances (cdr current) (car current))
                    (for-each
                        (lambda (coord)
                            (if (not (or
                                    (eq? (hash-table-ref grid coord) #\#)
                                    (hash-table-exists? distances coord)))
                                (xq:add (cons (+ 1 (car current)) coord))))
                        (get-adj (cdr current)))
                    (dijk grid xq distances))))))

(define (teleport-signature max-radius)
    ;; returns diamond-shaped mask of (cost . offset)
    ;; where offset is (+r . +c)
    (let ((result '()))
        (for-each
            (lambda (radius)
                (for-each
                    (lambda (i) (begin
                        (set! result (cons
                            (cons radius (cons i (- radius i))) ; east>south
                            result))
                        (set! result (cons
                            (cons radius (cons (- radius i) (- i))) ; south>west
                            result))
                        (set! result (cons
                            (cons radius (cons (- i) (- i radius))) ; west>north
                            result))
                        (set! result (cons
                            (cons radius (cons (- i radius) i)) ; north>east
                            result))))
                    [0 <: radius]))
            [1 <=: max-radius])
        result))

(define (shortcut-dists grid d-start d-end wallhack-amount)
    (let ((tp (teleport-signature wallhack-amount))
          (dists '()))
        (hash-table-walk grid
            (lambda (k v)
                (if (not (or (eq? v #\#) (eq? k 'start) (eq? k 'end)))
                    (let ((tp-locs (map
                            (lambda (cost-offset)
                                (cons
                                    (car cost-offset)
                                    (cons
                                        (+ (car k) (cadr cost-offset))
                                        (+ (cdr k) (cddr cost-offset)))))
                            tp)))
                        (for-each
                            (lambda (tp-dest)
                                (if (hash-table-exists? d-end (cdr tp-dest))
                                    (set! dists (cons
                                        (+
                                            (hash-table-ref d-start k)
                                            (car tp-dest)
                                            (hash-table-ref d-end (cdr tp-dest)))
                                        dists))))
                            tp-locs)))))
        dists))

(define (file->grid fname)
    (let ((r 0) (c 0)
          (grid (make-hash-table)))
        (string-for-each
            (lambda (chr)
                (begin
                    (case chr
                        ((#\S) (hash-table-set! grid 'start (cons r c)))
                        ((#\E) (hash-table-set! grid 'end   (cons r c))))
                    (if (eq? chr #\Newline)
                        (begin (set! r (+ r 1)) (set! c 0))
                        (begin
                            (hash-table-set! grid (cons r c) chr)
                            (set! c (+ c 1))))))
            (path-data fname))
        grid))


(define grid (file->grid "input20.txt"))

(define distance-from-start
    (dijk
        grid
        (java.util.PriorityQueue [(cons 0 (hash-table-ref grid 'start))])
        (make-hash-table)))
(define distance-from-end
    (dijk
        grid
        (java.util.PriorityQueue [(cons 0 (hash-table-ref grid 'end))])
        (make-hash-table)))

(define orig (hash-table-ref distance-from-end (hash-table-ref grid 'start)))
(format #t "~A~%" (count
    (lambda (x) (<= x (- orig 100)))
    (shortcut-dists grid distance-from-start distance-from-end 2)))
(format #t "~A~%" (count
    (lambda (x) (<= x (- orig 100)))
    (shortcut-dists grid distance-from-start distance-from-end 20)))
