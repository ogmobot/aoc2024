import heapq
import re

with open("input18.txt") as fp:
    lines = [line.strip() for line in fp]
GRIDSIZE = 70

grid = list()
for line in lines:
    a, b = line.split(",")
    grid.append((int(a), int(b)))

start = (0, 0)
end = (GRIDSIZE, GRIDSIZE)

def is_valid(c):
    x, y = c
    return (x >= 0 and x <= GRIDSIZE and y >= 0 and y <= GRIDSIZE)

def get_adj(grid, coord):
    #print(coord)
    x, y = coord
    cands = [
        (x + 1, y),
        (x - 1, y),
        (x, y + 1),
        (x, y - 1)
    ]
    return [c for c in cands if (c not in grid and is_valid(c))]

def dijk(grid, start):
    # heap contains (cost, path)
    paths = [
        (0, start),
    ]
    visited = dict()
    while paths:
        #print(paths)
        cost, last = heapq.heappop(paths)
        if last not in visited:
            visited[last] = cost
            for new_coord in get_adj(grid, last):
                heapq.heappush(paths,
                    (cost + 1, new_coord))
    return visited

visited = dijk(set(grid[:1024]), start)
print(visited[end])

# binary search
lower = 1025
upper = len(grid)
while lower + 1 < upper:
    fallen = (upper + lower) // 2
    visited = dijk(set(grid[:fallen]), start)
    if end not in visited:
        upper = fallen
    else:
        lower = fallen

res = grid[fallen-1]
print(f"{res[0]},{res[1]}")
