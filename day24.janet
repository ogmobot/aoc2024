#!/usr/bin/env janet

### Input processing ###

(defn line->constfn [text]
    # e.g. "x00: 1" => @{"x00" (fn [_] true)}
    (let [words  (string/split ": " text)
          output (parse (get words 1))]
        @{(get words 0) (fn [_] output)}))

(defn line->fn [text]
    # e.g. "abc AND def -> xyz"
    # => @{"xyz" (fn [db] (and (get db "abc") (get db "def")))}
    (let [words (string/split " " text)
          a     (get words 0)
          op    (case (get words 1)
                    "AND" band
                    "OR"  bor
                    "XOR" bxor)
          b     (get words 2)]
        @{
            (get words 4)
            (fn [db] (op ((get db a) db) ((get db b) db)))}))

### Working with logic circuits ###

(defn adder-sum [db prefix]
    (var i 0)
    (var total 0)
    (loop
        [output-fn :iterate (get db (string prefix (string/format "%02d" i)))]
        (let [result (output-fn db)]
            (set total (+ total (* result (math/exp2 i))))
            (++ i)))
    total)

### Main function ###

(def sections (string/split "\n\n" (string/trim (slurp "input24.txt"))))

(def db @{})
(each line (string/split "\n" (get sections 0))
    (merge-into db (line->constfn line)))
(each line (string/split "\n" (get sections 1))
    (merge-into db (line->fn line)))

(print (adder-sum db "z"))
