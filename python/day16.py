import heapq
import time

with open("input16.txt") as fp:
    lines = [line.strip() for line in fp]

START = None
END = None

grid = {}
for r, line in enumerate(lines):
    for c, symbol in enumerate(line):
        grid[(r, c)] = symbol
        if symbol == 'S':
            grid[(r, c)] = '.'
            START = (r, c)
        elif symbol == 'E':
            grid[(r, c)] = '.'
            END = (r, c)

assert START
assert END

D_UP = 0
D_LEFT = 1
D_DOWN = 2
D_RIGHT = 3

def turn_left(facing):
    return (facing + 1) % 4
def turn_right(facing):
    return (facing + 3) % 4

def get_adj(grid, coordface):
    # return pairs of added_cost, adjcoord
    r, c, facing = coordface
    new_r, new_c = r, c
    if facing == D_UP:
        new_r = r - 1
    elif facing == D_LEFT:
        new_c = c - 1
    elif facing == D_DOWN:
        new_r = r + 1
    elif facing == D_RIGHT:
        new_c = c + 1
    res = []
    res.append((1000, (r, c, turn_left(facing))))
    res.append((1000, (r, c, turn_right(facing))))
    if grid[(new_r, new_c)] == '.':
        res.append((1, (new_r, new_c, facing)))
    return res
    # "facing" could be removed -- have left and right turns be
    # turn-and-move-forward, at a cost of 1001

# Faster approach (takes <1s instead of 30 min)

def dijk(grid, start):
    # heap contains (cost, path)
    paths = [
        (0, start),
    ]
    visited = dict()
    while paths:
        cost, last = heapq.heappop(paths)
        if last not in visited:
            visited[last] = cost
            for added_cost, new_coord in get_adj(grid, last):
                heapq.heappush(paths,
                    (cost + added_cost, new_coord))
    return visited

start_time = time.time()

start_dists = dijk(grid, (START[0], START[1], D_RIGHT))
end_dists = [
    dijk(grid, (END[0], END[1], facing))
    for facing in range(4)
]
min_dist = min([start_dists[(END[0], END[1], facing)]
                for facing in range(4)])
print(min_dist)

best_tiles = set()
for r, c in grid.keys():
    if grid[(r, c)] == '#':
        continue
    for facing in range(4):
        combined_dist = (
            start_dists[(r, c, (facing + 2) % 4)] # approaching from opp. facing
            + min([end_dists[endface][(r, c, facing)] for endface in range(4)])
        )
        if combined_dist == min_dist:
            best_tiles.add((r, c))
print(len(best_tiles))

print("time", time.time() - start_time)

# Another approach: use Dijkstra's algorithm, but associate each location
# of "visited" with both a distance and the set of "best tiles" that can
# be used to reach that distance. (Search nodes need to contain the whole
# path.)
