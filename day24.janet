#!/usr/bin/env janet

### Input processing ###

(defn line->constfn [text]
    # e.g. "x00: 1" => @{"x00" (fn [_] true)}
    # If called with nil, returns nil instead.
    (let [words  (string/split ": " text)
          output (parse (get words 1))]
        @{
            (get words 0)
            (fn [arg]
                (case (type arg)
                    :table  output
                    :nil    nil))}))

(defn line->fn [text]
    # e.g. "abc AND def -> xyz"
    # => @{"xyz" (fn [db] (and (get db "abc") (get db "def")))}
    # If called with nil, returns parent nodes instead.
    (var cooldown false)
    (let [words (string/split " " text)
          a     (get words 0)
          op    (case (get words 1)
                    "AND" min
                    "OR"  bor
                    "XOR" bxor)
          b     (get words 2)]
        @{
            (get words 4)
            (fn [arg]
                (case (type arg)
                    :table
                        (if cooldown
                            -1
                            (do
                                (set cooldown true)
                                (def res (op ((get arg a) arg) ((get arg b) arg)))
                                (set cooldown false)
                                res))
                    :nil    [a b]))}))

### Working with logic circuits ###

(defn adder-get-int [db prefix]
    (var i 0)
    (var total 0)
    (loop
        [output-fn :iterate (get db (string/format "%s%02d" prefix i))]
        (let [result (output-fn db)]
            (+= total (* result (math/exp2 i)))
            (++ i)))
    total)

(defn db-set-inputs [db x x-value y y-value]
    (var i 0)
    (var xacc x-value) (var yacc y-value)
    (while (get db (string/format "%s%02d" x i))
        (let [xstr (string/format "%s%02d" x i)
              ystr (string/format "%s%02d" y i)
              xbit (% xacc 2)
              ybit (% yacc 2)]
            (put db xstr (fn [arg] (case (type arg) :table xbit :nil nil)))
            (put db ystr (fn [arg] (case (type arg) :table ybit :nil nil)))
            (set xacc (math/floor (/ xacc 2)))
            (set yacc (math/floor (/ yacc 2)))
            (++ i))))

(defn select-binary-digit [n i]
    (% (math/floor (/ n (math/exp2 i))) 2))

(defn seek-first-error [db x y z]
    # Finds the smallest ii for which zii zjj doesn't match xii + yii
    (var done false)
    (var i 0)
    (var result nil)
    (while (not done)
        #(print (string/format "i=%d" i))
        (let [zistr (string/format "%s%02d" z i)
              zjstr (string/format "%s%02d" z (+ i 1))
              zii   (get db zistr)
              zjj   (get db zjstr)]
            (if (and zii zjj)
                (do
                    # no carry set
                    (db-set-inputs db "x" 0
                                      "y" (math/exp2 i))
                    (def z01x0 (zii db))
                    (def z01c0 (zjj db))
                    (db-set-inputs db "x" (math/exp2 i)
                                      "y" 0)
                    (def z10x0 (zii db))
                    (def z10c0 (zjj db))
                    (db-set-inputs db "x" (math/exp2 i)
                                      "y" (math/exp2 i))
                    (def z11x0 (zii db))
                    (def z11c0 (zjj db))
                    (set done (not (and
                        (= z01x0 1) (= z01c0 0)
                        (= z10x0 1) (= z10c0 0)
                        (= z11x0 0) (= z11c0 1))))
                    (if (and (not done) (> i 0))
                        (let [carry (math/exp2 (- i 1))]
                            (db-set-inputs db "x" carry
                                              "y" carry)
                            (def z00x1 (zii db))
                            (def z00c1 (zjj db))
                            (db-set-inputs db "x" carry
                                              "y" (+ carry (math/exp2 i)))
                            (def z01x1 (zii db))
                            (def z01c1 (zjj db))
                            (db-set-inputs db "x" (+ carry (math/exp2 i))
                                              "y" carry)
                            (def z10x1 (zii db))
                            (def z10c1 (zjj db))
                            (db-set-inputs db "x" (+ carry (math/exp2 i))
                                              "y" (+ carry (math/exp2 i)))
                            (def z11x1 (zii db))
                            (def z11c1 (zjj db))
                        (set done (not (and
                            (= z00x1 1) (= z00c1 0)
                            (= z01x1 0) (= z01c1 1)
                            (= z10x1 0) (= z10c1 1)
                            (= z11x1 1) (= z11c1 1))))))
                    (set result i))
                (do
                    (set done true)
                    (set result nil)))
            (++ i)))
    result)

(defn tag-all-parents [db tags wire tag]
    # assumes only input wires start with x or y
    (if (and (not= (string/slice wire 0 1) "x")
             (not= (string/slice wire 0 1) "y")
             (not (get tags wire)))
        (let [parents ((get db wire) nil)]
            (put tags wire tag)
            (each parent parents (tag-all-parents db tags parent tag))))
    tags)

(defn determine-adder [db]
    # determines which half-adder each wire belongs to
    (var i 0)
    (var tags @{}) # @{"abc" 0 "def" 0 ... "xyz" 44}
    (while (get db (string/format "x%02d" i))
        (tag-all-parents db tags (string/format "z%02d" i) i)
        (++ i))
    tags)

(defn all-relevant-wires [tags error-index]
    # due to how tags are set up, we'll need to check up to error-index + 2
    (var result @[])
    (loop [[wire tag] :pairs tags
           :when (and (>= tag error-index) (<= tag (+ error-index 2)))]
        (array/push result wire))
    result)

(defn switch-wires [db a b]
    (let [tmp (get db a)]
        (put db a (get db b))
        (put db b tmp)))

(defn fix-error-at [db tags relevant-wires error-index]
    #(print (string/format "fixing error at adder %d..." error-index))
    (var switch-results @[])
    (loop [i :range [0 (length relevant-wires)]]
    (loop [j :range [0 i]]
        (let [sandbox (merge @{} db)
              a (get relevant-wires i)
              b (get relevant-wires j)]
            #(print (string/format "i=%d j=%d" i j))
            (switch-wires sandbox a b)
            (array/push switch-results
                [(seek-first-error sandbox "x" "y" "z") [a b]]))))
    #(pp (sort switch-results))
    (get (array/pop (sort switch-results)) 1))

(defn fix-next-error [db]
    (var all-switches @[])
    (let [tags (determine-adder db)
          error-index (seek-first-error db "x" "y" "z")]
        (if (= error-index nil)
            nil
            (let [switched (fix-error-at db tags
                            (all-relevant-wires tags error-index)
                            error-index)]
                #(pp switched)
                (switch-wires db (get switched 0) (get switched 1))
                switched))))

(defn fix-all-errors [db already-switched]
    (if (= (def switched (fix-next-error db)) nil)
        already-switched
        (fix-all-errors db (array/push already-switched switched))))

### Main function ###

(def sections (string/split "\n\n" (string/trim (slurp "input24.txt"))))

(def db @{})
(each line (string/split "\n" (get sections 0))
    (merge-into db (line->constfn line)))
(each line (string/split "\n" (get sections 1))
    (merge-into db (line->fn line)))

(print (adder-get-int db "z"))

# (def switches @[
#     ["fgc" "z12"] # 11-12
#     ["mtj" "z29"] # 28-29
#     ["vvm" "dgr"] # 33-34
#     ["dtv" "z37"] # 36-37
# ])
# (each ab switches
#     (switch-wires db (get ab 0) (get ab 1)))

(def switches (fix-all-errors db @[]))
(print (string/join (sort (flatten switches)) ","))
