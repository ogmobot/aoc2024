with open("input14.txt") as fp:
    lines = [line.strip() for line in fp]

import re
from functools import reduce

WIDTH = 101
HEIGHT = 103
robots = []
for line in lines:
    m = re.search(r"p=(-?\d+),(-?\d+) v=(-?\d+),(-?\d+)", line)
    robots.append({
        'p': (int(m.group(1)), int(m.group(2))),
        'v': (int(m.group(3)), int(m.group(4)))
    })

def move(robot):
    v = robot['v']
    p = robot['p']
    robot['p'] = ((p[0] + v[0]) % WIDTH, (p[1] + v[1]) % HEIGHT)
    return

def find_quad(robot):
    if robot['p'][0] < WIDTH // 2:
        if robot['p'][1] < HEIGHT // 2:
            return 1
        elif robot['p'][1] > HEIGHT // 2:
            return 2
    elif robot['p'][0] > WIDTH // 2:
        if robot['p'][1] < HEIGHT // 2:
            return 3
        elif robot['p'][1] > HEIGHT // 2:
            return 4
    return 0

def safety(robots):
    quads = [0, 0, 0, 0, 0]
    for r in robots:
        quads[find_quad(r)] += 1
    return quads[1] * quads[2] * quads[3] * quads[4]

def display(robots):
    buffer = [['.' for _ in range(WIDTH)] for _ in range(HEIGHT)]
    for rob in robots:
        buffer[rob['p'][1]][rob['p'][0]] = '@'
    print('\n'.join(''.join(buffer[r]) for r in range(HEIGHT)))

#for _ in range(100):
    #for r in robots:
        #move(r)
print(safety(robots))
i = 0
while True:
    if (i % 101 == 18): # trial and error. Could also search for a 3x3 @@@
        print(i)
        display(robots)
        input()
    for r in robots:
        move(r)
    i += 1


