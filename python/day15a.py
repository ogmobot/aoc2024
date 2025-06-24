S_ROBOT = '@'
S_ROCK = 'O'
S_WALL = '#'
S_EMPTY = '.'

with open("input15.txt") as fp:
    sections = fp.read().split("\n\n")
    #lines = [line.strip() for line in sections[1].split("\n")]
    moves = sections[1].replace("\n", "")
    grid = {}
    for r, line in enumerate(sections[0].split("\n")):
        for c, symbol in enumerate(line):
            grid[(r, c)] = symbol
            if symbol == '@':
                robot = (r, c)
                grid[robot] = '.'

import re
import functools
import operator


def attempt_push(grid, from_coord, direction):
    to_coord = (from_coord[0] + direction[0], from_coord[1] + direction[1])
    if grid[to_coord] == S_EMPTY:
        grid[from_coord] = S_EMPTY
        grid[to_coord] = S_ROCK
        return True
    elif grid[to_coord] == S_ROCK:
        if attempt_push(grid, to_coord, direction):
            grid[from_coord] = S_EMPTY
            grid[to_coord] = S_ROCK
            return True
    return False

def attempt_move(grid, from_coord, direction):
    to_coord = (from_coord[0] + direction[0], from_coord[1] + direction[1])
    if grid[to_coord] == S_EMPTY:
        return to_coord
    elif grid[to_coord] == S_ROCK:
        if attempt_push(grid, to_coord, direction):
            return to_coord
    return from_coord


movemap = {
    '<': (0, -1),
    '>': (0, 1),
    '^': (-1, 0),
    'v': (1, 0)
}

for move in moves:
    robot = attempt_move(grid, robot, movemap[move])

total = 0
for r, c in grid.keys():
    if grid[(r, c)] == S_ROCK:
        total += (100 * r) + c

print(total)
