#!/usr/bin/env bash
heol_bin="uxncli $HOME/.local/bin/heol.rom"

# Heol seems to be reaching some sort of limit (recursion? memory?)
# when dealing with the puzzle input.
# Run a seprate instance of Heol for each input line.
out_dir=$(mktemp -d)

while read input_line; do
    # Name temp files after input, so grepping for weird output
    # also finds the input that produced it
    # (It would be better to not create 1000 temporary files)
    heol_out=$(mktemp -p $out_dir "$input_line.XXX")
    # Append one line of input to the day02.heol program, then send it to Heol
    echo "(solve '(" $input_line "))" | cat "day02.heol" - \
        | $heol_bin 2>"$heol_out" &
done < input02.txt
wait

cat $out_dir/* | grep -o "[01]\s\.\s[01]" \
    | awk -F " . " '{ p1 += $1; p2 += $2 } END { print p1; print p2 }'
