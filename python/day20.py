import heapq
import time
import itertools

with open("input20.txt") as fp:
    lines = [line.strip() for line in fp]

lines_  = """###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############""".split("\n")

maxr, maxc = 0, 0
grid = {}
for r, line in enumerate(lines):
    for c, symbol in enumerate(line):
        grid[(r, c)] = symbol
        if r >= maxr: maxr = r
        if c >= maxc: maxc = c
        if symbol == 'S':
            START = (r, c)
        if symbol == 'E':
            END = (r, c)

def manhattan(a, b):
    return abs(a[0]-b[0])+abs(a[1]-b[1])

def manhattan_neighbourhood(a, dist):
    for r in range(a[0]-dist, a[0]+dist+1):
        for c in range(a[1]-dist, a[1]+dist+1):
            if manhattan(a, (r, c)) <= dist:
                yield (r, c)

def valid_coord(grid, coord):
    r, c = coord
    return (
        (grid.get((r, c)) != '#')
        and (r >= 0 and c >= 0 and r <= maxr and c <= maxc))

def get_adj(grid, coord):
    r, c = coord
    options = [
            (1, (r + 1, c)),
            (1, (r - 1, c)),
            (1, (r, c + 1)),
            (1, (r, c - 1)),
    ]
    return [(cost, x) for cost, x in options if valid_coord(grid, x)]

def dijk(grid, start):
    # heap contains (cost, path)
    paths = [
        (0, start),
    ]
    visited = dict()
    while paths:
        cost, last = heapq.heappop(paths)
        #cost, last = paths.pop()
        if last not in visited:
            visited[last] = cost
            for added_cost, new_coord in get_adj(grid, last):
                heapq.heappush(paths,
                #paths.append(
                    (cost + added_cost, new_coord))
    return visited

def solve(grid, jumplen, what_a):
    dist_to_start = dijk(grid, START)
    dist_to_end = dijk(grid, END)
    bestlen = dist_to_start[END]

    total = 0
    for jump_from in dist_to_start:
        for jump_to in manhattan_neighbourhood(jump_from, jumplen):
            if jump_to in dist_to_end:
                savings = bestlen - (dist_to_start[jump_from]
                                     + dist_to_end[jump_to]
                                     + manhattan(jump_from, jump_to))
                if what_a(savings): # By Grogthar's Hammer!
                    total += 1
    return total

print(solve(grid, 2, (lambda s: s >= 100)))
print(solve(grid, 20, (lambda s: s >= 100)))
