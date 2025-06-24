from math import gcd

with open("input08.txt") as fp:
    lines = [line.strip() for line in fp]

lines_ = """............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............""".split("\n")

antennae = set()
grid = {}
for r, line in enumerate(lines):
    for c, symbol in enumerate(line):
        grid[(r, c)] = symbol
        if symbol.isalnum():
            antennae.add((r, c))

antinodes_1 = set()
antinodes_2 = set()
for key in antennae:
    symbol = grid.get(key)
    for k2 in antennae:
        if k2 == key:
            continue
        if grid[k2] != grid[key]:
            continue
        # part 1
        dr = k2[0] - key[0]
        dc = k2[1] - key[1]
        antinodes_1.add((k2[0] + dr, k2[1] + dc))
        antinodes_1.add((key[0] - dr, key[1] - dc))
        # part 2
        dr = dr // gcd(dr, dc)
        dc = dc // gcd(dr, dc) # Turns out this wasn't needed
        rr = k2[0]
        cc = k2[1]
        while (rr, cc) in grid:
            antinodes_2.add((rr, cc))
            rr += dr
            cc += dc
        rr = k2[0]
        cc = k2[1]
        while (rr, cc) in grid:
            antinodes_2.add((rr, cc))
            rr -= dr
            cc -= dc

print(len(antinodes_1.intersection(grid)))
print(len(antinodes_2))
