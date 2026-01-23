#!/usr/bin/env bash

orig_input="input10.txt"
orig_prog="day10.scad"
prog_input=$(mktemp --suffix=".input")
prog_file=$(mktemp --suffix=".scad")
cat <(echo -n "text = \"") \
    $orig_input \
    <(echo -n "\";") \
    | tr '\n' '\a' | sed 's/\a/\\n/g' \
    > $prog_input
sed -e '/<<<INPUT_TEXT_HERE>>>/{' -e "r $prog_input" -e 'd }' $orig_prog \
    > $prog_file
openscad $prog_file -o - --export-format asciistl 2>&1 \
    | grep "^ECHO: " \
    | sed "s/^ECHO: //"

rm $prog_input
rm $prog_file
