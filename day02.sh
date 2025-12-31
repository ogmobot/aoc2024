#!/usr/bin/env bash
heol_bin="uxncli $HOME/.local/bin/heol.rom"

awk "{ print \"(solve '(\" \$line \"))\" }" input02.txt \
    | cat day02.heol - \
    | $heol_bin 2>/dev/null \
    | awk '{ p1 += $1 ; p2 += $2 } END { print p1 ; print p2 }'
