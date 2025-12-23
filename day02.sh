#!/usr/bin/env bash
heol_bin="uxncli $HOME/.local/bin/heol.rom"

# Heol seems to be reaching some sort of limit (recursion? memory?)
# when dealing with the puzzle input.
# Run a seprate instance of Heol for each input line.

# Use as standard input file [<] the result of this command [<(...)].
< <(while read input_line; do
    # Append one line of input to the day02.heol program, then send it to Heol.
    # Pipe to tail to ensure output arrives by line, not by character.
    echo "(solve '(" "$input_line" "))" \
        | cat "day02.heol" - \
        | $heol_bin 2>/dev/null \
        | tail -1 &
done < input02.txt; wait) \
    awk '{ p1 += $1; p2 += $2 } END { print p1; print p2 }'
