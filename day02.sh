#!/usr/bin/env bash
heol_bin="uxncli $HOME/.local/bin/heol.rom"

# Heol seems to be reaching some sort of limit (recursion? memory?)
# when dealing with the puzzle input.
# Run a seprate instance of Heol for each input line.

# Use as standard input file [<] the result of this command [<(...)].
< <(while read input_line; do
    # Append one line of input to the day02.heol program, then send it to Heol.
    # Find output lines in the form "(0 . 0)".
    echo "(solve '(" $input_line "))" \
        | cat "day02.heol" - \
        | $heol_bin 2>&1 \
        | grep -o "[01]\s\.\s[01]" &
done < input02.txt; wait) \
    awk -F " . " '{ p1 += $1; p2 += $2 } END { print p1; print p2 }'
