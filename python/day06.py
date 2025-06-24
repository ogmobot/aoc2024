with open("input06.txt") as fp:
    lines = [line.strip() for line in fp]

lines_ = """....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...""".split("\n")

maxr, maxc = 0, 0
grid = {}
for r, line in enumerate(lines):
    for c, symbol in enumerate(line):
        grid[(r, c)] = symbol
        if symbol == "^":
             start_y, start_x = r, c

visited = set()

dx, dy = 0, -1

def turnright(dx, dy):
    return -dy, dx

x, y = start_x, start_y
while (y, x) in grid:
    visited.add((y, x))
    newx, newy = x + dx, y + dy
    while (newy, newx) in grid and grid[(newy, newx)] == "#":
        dx, dy = turnright(dx, dy)
        newx, newy = x + dx, y + dy
    x, y = newx, newy

print(len(visited))

loopers = 0
for ob_r, ob_c in visited - {(start_y, start_x)}:
    x, y = start_x, start_y
    dx, dy = 0, -1
    visitface = set()
    while (y, x) in grid:
        if (y, x, dy, dx) in visitface:
            loopers += 1
            #print(f"{ob_r=} {ob_c=}")
            break
        newx, newy = x + dx, y + dy
        while (newy, newx) in grid and (grid[(newy, newx)] == "#" or ((newx, newy) == (ob_c, ob_r))):
            visitface.add((y, x, dy, dx))
            dx, dy = turnright(dx, dy)
            newx, newy = x + dx, y + dy
        x, y = newx, newy
        #print(f"({x=},{y=})", end="")
    #print()
print(loopers)
