#!/usr/bin/env bash
heol_bin="uxncli $HOME/.local/bin/heol.rom"

# Heol seems to be reaching some sort of limit (recursion? memory?)
# when dealing with the puzzle input.
# Run a seprate instance of Heol for each input line.
out_dir=$(mktemp -d)
heol_pids=()

while read input_line; do
    # Name temp files after input, so grepping for weird output
    # also finds the input that produced it
    heol_out=$(mktemp -p $out_dir "$input_line.XXX")
    # Start Heol, load the day02.heol program, and send it a single input line
    # (Current method is to echo the entire contents of day02.heol)
    # (There is almost certainly a nicer way to do this)
    echo `cat day02.heol` "(solve '(" $input_line "))" \
        | $heol_bin 2>"$heol_out" &
    heol_pid=$!
    heol_pids+=($heol_pid)
done < input02.txt
# The rest of the script will get erratic results if the Heol processes
# haven't finished running by this point
for hp in "${heol_pids[@]}"; do
    wait -f $hp
done
# If the Heol program doesn't produce output in the form (0 . 0),
# I want to know about it!!
grep -L -o "[01]\s\.\s[01]" $out_dir/*
# 46 43 44 43 42
# originally wasn't classified as "safeish" but should be.
# The solver saw the jump 46->43 was fine, so didn't consider
# removing the 43.
cat $out_dir/* | grep -o "[01]\s\.\s[01]" | \
    awk -F " . " \
        '{ p1 += $1; p2 += $2 } \
        END { print p1; print p2 }'
