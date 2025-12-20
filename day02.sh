#!/usr/bin/env bash
heol_bin="uxncli $HOME/.local/bin/heol.rom"

# Heol seems to be reaching some sort of limit (recursion? memory?)
# when dealing with the puzzle input.
# Run a seprate instance of Heol for each input line.
out_dir=$(mktemp -d)
heol_pids=()

while read p; do
    heol_out=$(mktemp -p $out_dir "$p.XXX")
    echo `cat day02.heol` "(solve '(" $p "))" | $heol_bin 2>"$heol_out" &
    heol_pid=$!
    heol_pids+=($heol_pid)
done < input02.txt
for hp in "${heol_pids[@]}"; do
    wait -f $hp
done
grep -L -o "[01]\s\.\s[01]" $out_dir/*
# 45 44 42 41 39 36 33 29
# 58 56 55 54 52 51 50 51
# In both cases, it's the value with index 7...
cat $out_dir/* | grep -o "[01]\s\.\s[01]" | \
    awk -F " . " \
        '{ p1 += $1; p2 += $2; echo $0 } \
        END { printf("%d %d\n", p1, p2) }'
