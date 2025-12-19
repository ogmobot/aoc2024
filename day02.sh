#!/usr/bin/env bash
heol_bin="uxncli $HOME/.local/bin/heol.rom"

# Heol can't always deal with long lists.
# Rather than attempting to read a 1000-element-long list,
# go through the input line-by-line.
heol_in=/tmp/data.pipe_in
mkfifo $heol_in

# If heol is upset that there's no available data,
# this will ensure pipe stays open.
#sleep 1 > $heol_in &

# Count the number of #t (safe) the program outputs
$heol_bin 2>&1 < $heol_in | grep -c "#t$" &
heol_pid=$!
# Load program file
cat day02.heol > $heol_in
# Send each line of file to program
awk '{ printf("(safe? %c(%s))", 39, $0) }' input02.txt > $heol_in

wait $heol_pid
rm -f $heol_in
