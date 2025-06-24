with open("input25.txt") as fp:
    grids = fp.read().strip().split("\n\n")

def parse_key(grid):
    lines = grid.split("\n")
    result = [-1] * 5
    for row in range(7):
        for col in range(5):
            if lines[row][col] == "#":
                result[col] += 1
    return result

def parse_lock(grid):
    lines = grid.split("\n")
    result = [-1] * 5
    for row in range(6, -1, -1):
        for col in range(5):
            if lines[row][col] == "#":
                result[col] += 1
    return result

def fits(key, lock):
    return all(key[i] + lock[i] <= 5 for i in range(5))

locks = []
keys = []
for g in grids:
    if all(c == '#' for c in g.split("\n")[0]):
        # This is a key
        keys.append(parse_key(g))
    else:
        # This is a lock
        locks.append(parse_lock(g))

total = 0
for k in keys:
    for l in locks:
        if fits(k, l):
            total += 1
print(total)
