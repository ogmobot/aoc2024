with open("input12.txt") as fp:
    lines = [line.strip() for line in fp]

from collections import defaultdict

lines_ = """AAAAAA
AAABBA
AAABBA
ABBAAA
ABBAAA
AAAAAA
""".split("\n")

grid = {}
for r, line in enumerate(lines):
    for c, symbol in enumerate(line):
        grid[(r, c)] = symbol

def get_adj(tup):
    return [
        (tup[0] + 1, tup[1]),
        (tup[0] - 1, tup[1]),
        (tup[0], tup[1] + 1),
        (tup[0], tup[1] - 1)]

def floodfill(grid, coord):
    result = set()
    front = set([coord])
    while front:
        #print(front)
        current = front.pop()
        if current in result:
            pass
        result.add(current)
        for adj in get_adj(current):
            if adj not in result and adj not in front:
                if grid.get(adj, None) == grid[coord]:
                    front.add(adj)
    #print(f'floodfilled region {grid[coord]}')
    return result

regions = []
for coord in grid:
    if not any((coord in region) for region in regions):
        regions.append(floodfill(grid, coord))
        #print(regions)

def get_perimeter(region):
    result = 0
    for item in region:
        for adj in get_adj(item):
            if adj not in region:
                result += 1
    return result

def get_edges(region):
    result = 0
    top_edges = set()
    bottom_edges = set()
    left_edges = set()
    right_edges = set()
    for item in region:
        if ((item[0] - 1, item[1]) not in region):
            top_edges.add(item)
        if ((item[0] + 1, item[1]) not in region):
            bottom_edges.add(item)
        if ((item[0], item[1] - 1) not in region):
            left_edges.add(item)
        if ((item[0], item[1] + 1) not in region):
            right_edges.add(item)
    #print(top_edges)
    return (len(merge_edges(top_edges, 0, 1))
        + len(merge_edges(bottom_edges, 0, 1))
        + len(merge_edges(left_edges, 1, 0))
        + len(merge_edges(right_edges, 1, 0)))

def merge_edges(edges, dr, dc):
    edges = edges.copy()
    result = set()
    while edges:
        temp = set([edges.pop()])
        new = True
        while new:
            new = False
            for e in edges:
                if (e[0]+dr, e[1]+dc) in temp or (e[0]-dr, e[1]-dc) in temp:
                    new = True
                    temp.add(e)
                    edges.remove(e)
                    break
        result.add(temp.pop())
    return result

def get_score(region, f):
    return len(region) * f(region)

total_1 = 0
total_2 = 0
for region in regions:
    total_1 += get_score(region, get_perimeter)
    total_2 += get_score(region, get_edges)
print(total_1)
print(total_2)
