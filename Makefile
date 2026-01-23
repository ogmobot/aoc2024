RUNNABLES := day01.sh day02.sh day03    day04.sh day05.be \
             day06    day07.sh day08.js day09    day10.sh

dummy:

all: $(RUNNABLES)

day01.sh: day01.a68
	a68g --compile day01.a68

day03: day03.HC
	hcc day03.HC -o day03

day04.sh: day04/src/day04.gleam
	cd day04; gleam export erlang-shipment
	echo "#!/usr/bin/env bash" > day04.sh
	echo "cd day04; build/erlang-shipment/entrypoint.sh run" >> day04.sh
	chmod a+x day04.sh

day06: day06.v
	v -prod -cc gcc -cflags "-march=native -O2" day06.v

day07.sh: day07.ab
	amber build day07.ab

day08.js: day08.grace
	minigrace-js --make --gracelib `echo $$GRACE_MODULE_PATH` day08.grace
# (run with "grace day08.js")

day09: day09.m
	clang `gnustep-config --objc-flags` `gnustep-config --objc-libs` \
        -lgnustep-base \
        -I/usr/lib/gcc/x86_64-linux-gnu/11/include/ \
        day09.m -o day09

