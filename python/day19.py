import heapq
import re
import functools

with open("input19.txt") as fp:
    data = fp.read()

sections = data.strip().split("\n\n")
towels = sections[0].split(", ")
designs = sections[1].split("\n")

@functools.cache
def matchmake(towels, design):
    total = 0
    if design == "":
        return 1
    for towel in towels:
        if design.startswith(towel):
            total += matchmake(towels, design[len(towel):])
    return total

part_1 = 0
part_2 = 0
towels = tuple(towels)
for des in designs:
    match = matchmake(towels, des)
    part_1 += int(match != 0)
    part_2 += match
print(part_1)
print(part_2)
