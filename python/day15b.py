S_ROBOT = '@'
S_ROCK = 'O'
S_WALL = '#'
S_EMPTY = '.'
import copy
maxc = 0
maxr = 0
with open("input15.txt") as fp:
    sections = fp.read().split("\n\n")
    sections_ = """##########
#..O..O.O#
#......O.#
#.OO..O.O#
#..O@..O.#
#O#..O...#
#O..O..O.#
#.OO.O.OO#
#....O...#
##########

<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^""".split("\n\n")
    sections_ = """#######
#...#.#
#.....#
#..OO@#
#..O..#
#.....#
#######

<vv<<^^<<^^""".split("\n\n")
    #lines = [line.strip() for line in sections[1].split("\n")]
    moves = sections[1].replace("\n", "")
    grid = {}
    for r, line in enumerate(sections[0].split("\n")):
        for c, symbol in enumerate(line):
            if 2*c > maxc:
                maxc = 2*c + 1
            if r > maxr:
                maxr = r
            grid[(r, 2*c)] = symbol
            grid[(r, (2*c)+1)] = symbol
            if symbol == '@':
                robot = (r, 2*c)
                grid[(r, 2*c)] = '.'
                grid[(r, (2*c)+1)] = '.'
            if symbol == 'O':
                grid[(r, 2*c)] = '['
                grid[(r, (2*c)+1)] = ']'

import re
import functools
import operator


def attempt_push(from_coord, direction):
    global grid
    backup = grid.copy()
    if grid[from_coord] == S_EMPTY:
        return True
    if grid[from_coord] == S_WALL:
        return False
    to_coord = (from_coord[0] + direction[0], from_coord[1] + direction[1])
    if grid[from_coord] == '[': # won't go left
        from_coord_ = (from_coord[0], from_coord[1] + 1)
        to_coord_ = (to_coord[0], to_coord[1] + 1)
        s_me = '['
        s_other = ']'
    elif grid[from_coord] == ']':
        from_coord_ = (from_coord[0], from_coord[1] - 1)
        to_coord_ = (to_coord[0], to_coord[1] - 1)
        s_me = ']'
        s_other = '['
    grid[from_coord] = S_EMPTY
    grid[from_coord_] = S_EMPTY
    if attempt_push(to_coord, direction) and attempt_push(to_coord_, direction):
        grid[to_coord] = s_me
        grid[to_coord_] = s_other
        #print('true')
        return True
    else:
        grid = backup
        #print('false')
        return False

def attempt_move(grid, from_coord, direction):
    to_coord = (from_coord[0] + direction[0], from_coord[1] + direction[1])
    if grid[to_coord] == S_EMPTY:
        return to_coord
    elif grid[to_coord] in ['[', ']']:
        if attempt_push(to_coord, direction):
            return to_coord
    return from_coord

def draw_grid():
    for r in range(maxr + 1):
        print(''.join(grid[(r, c)] for c in range(maxc + 1)))
    return

movemap = {
    '<': (0, -1),
    '>': (0, 1),
    '^': (-1, 0),
    'v': (1, 0)
}

for move in moves:
    robot = attempt_move(grid, robot, movemap[move])
    #draw_grid()

total = 0
for r, c in grid.keys():
    if grid[(r, c)] == '[':
        if c > (maxc//2):
            total += (100 * r) + c
        else:
            total += (100 * r) + c

print(total)
