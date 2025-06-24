with open("input10.txt") as fp:
    lines = [line.strip() for line in fp]

def get_adj(tup):
    return [
        (tup[0] + 1, tup[1]),
        (tup[0] - 1, tup[1]),
        (tup[0], tup[1] + 1),
        (tup[0], tup[1] - 1)
    ]

lines_ = """89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732""".split("\n")

def score(grid, head):
    visited = set()
    fronts = [head]
    ends = set()
    while fronts:
        current = fronts.pop()
        if current in visited:
            continue
        visited.add(current)
        if grid[current] == "9":
            ends.add(current)
            continue
        for adj in get_adj(current):
            if grid.get(adj, ".") == ".":
                continue
            if adj not in visited:
                if int(grid.get(adj, -1)) == 1 + int(grid[current]):
                    fronts.append(adj)
    return len(ends)

def rating(grid, fronts):
    visited = set()
    ends = set()
    ways_to_get = {coord: 0 for coord in grid}
    for f in fronts:
        ways_to_get[f] = 1
    result = 0
    while True:
        if grid[fronts[0]] == '9':
            return sum(ways_to_get[f] for f in fronts)
        new_fronts = []
        for current in fronts:
            for adj in get_adj(current):
                if int(grid.get(adj, -1)) == 1 + int(grid[current]):
                    ways_to_get[adj] += ways_to_get[current]
                    new_fronts.append(adj)
        fronts = list(set(new_fronts))

trailheads = []
grid = {}
for r, line in enumerate(lines):
    for c, symbol in enumerate(line):
        grid[(r, c)] = symbol
        if symbol == "0":
            trailheads.append((r, c))

grand = 0
for th in trailheads:
    grand += score(grid, th)
print(grand)

print(rating(grid, trailheads))

