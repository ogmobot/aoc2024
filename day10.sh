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
if [ -z "$1" ]; then
    openscad $prog_file -o - --export-format asciistl 2>&1 \
        | grep "^ECHO: " \
        | sed "s/^ECHO: //"
else
    openscad $prog_file -D "doModel=true" -o "$1"
fi

rm $prog_input
rm $prog_file
