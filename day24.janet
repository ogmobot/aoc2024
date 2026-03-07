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
    (let [words (string/split " " text)
          a     (get words 0)
          op    (case (get words 1)
                    "AND" band
                    "OR"  bor
                    "XOR" bxor)
          b     (get words 2)]
        @{
            (get words 4)
            (fn [arg]
                (case (type arg)
                    :table  (op ((get arg a) arg) ((get arg b) arg))
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
            (put db xstr (fn [_] xbit))
            (put db ystr (fn [_] ybit))
            (set xacc (math/floor (/ xacc 2)))
            (set yacc (math/floor (/ yacc 2)))
            (++ i))))

(defn seek-first-error [db x y z]
    # Finds the smallest ii for which zii zjj doesn't match xii + yii
    (var done false)
    (var i 0)
    (var result nil)
    (while (not done)
        (let [zistr (string/format "%s%02d" z i)
              zjstr (string/format "%s%02d" z (+ i 1))
              zii   (get db zistr)
              zjj   (get db zjstr)]
            (if (and zii zjj)
                (do
                    # 0 / 0 not necessary
                    (db-set-inputs db "x" 0 "y" (math/exp2 i))
                    (def z01x (zii db))
                    (def z01c (zjj db))
                    (db-set-inputs db "x" (math/exp2 i) "y" 0)
                    (def z10x (zii db))
                    (def z10c (zjj db))
                    (db-set-inputs db "x" (math/exp2 i) "y" (math/exp2 i))
                    (def z11x (zii db))
                    (def z11c (zjj db))
                    (set done (not (and
                        (= z01x 1) (= z01c 0)
                        (= z10x 1) (= z10c 0)
                        (= z11x 0) (= z11c 1))))
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

(defn switch-wires [db a b]
    (let [tmp (get db a)]
        (put db a (get db b))
        (put db b tmp)))

### Main function ###

(def sections (string/split "\n\n" (string/trim (slurp "input24.txt"))))

(def db @{})
(each line (string/split "\n" (get sections 0))
    (merge-into db (line->constfn line)))
(each line (string/split "\n" (get sections 1))
    (merge-into db (line->fn line)))

(print (adder-get-int db "z"))

# (pp (seek-first-error db "x" "y" "z"))
(def tags (determine-adder db))
# (pp (get tags "fgc")) # 13
# (pp (get tags "mtj")) # 30
# (pp (get tags "vvm")) # 34
# (pp (get tags "dgr")) # 33
# (pp (get tags "dtv")) # 38
(def switches @[
    ["fgc" "z12"] # 11-12
    ["mtj" "z29"] # 28-29
    ["vvm" "dgr"] # 33-34
    ["dtv" "z37"] # 36-37
])
(each ab switches
    (switch-wires db (get ab 0) (get ab 1)))
(print (string/join (sort (flatten switches)) ","))
