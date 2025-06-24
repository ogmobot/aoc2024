import re

with open("input13.txt") as fp:
    sections = fp.read().split("\n\n")

sections_ = """Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400

Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176

Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450

Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279""".split("\n\n")

def solve(ax, ay, bx, by, px, py):
    # Source: worked it out on a piece of paper
    if ay * bx == ax * by:
        if by == 0:
            return (-1, -1)
        else:
            return (0, py // by)
    elif bx == 0:
        # ax and by can't be 0
        return (px // ax, 0)
    else:
        a = (bx*py - by*px)//(ay*bx - ax*by)
        b = (px - a*ax)//bx
        return (a, b)

total_1 = 0
total_2 = 0

for i, thing in enumerate(sections):
    #print(repr(thing))
    lines = thing.split("\n")
    re_a = re.search(r"X\+(\d+), Y\+(\d+)", lines[0])
    re_b = re.search(r"X\+(\d+), Y\+(\d+)", lines[1])
    re_prize = re.search(r"X=(\d+), Y=(\d+)", lines[2])

    ax = int(re_a.group(1))
    ay = int(re_a.group(2))
    bx = int(re_b.group(1))
    by = int(re_b.group(2))
    px = int(re_prize.group(1))
    py = int(re_prize.group(2))

    a, b = solve(ax, ay, bx, by, px, py)
    if a >= 0 and b >= 0 and a * ax + b * bx == px and a * ay + b * by == py:
        total_1 += (3*a + b)
    BIGNUM = 10000000000000
    px += BIGNUM
    py += BIGNUM
    a, b = solve(ax, ay, bx, by, px, py)
    if a >= 0 and b >= 0 and a * ax + b * bx == px and a * ay + b * by == py:
        total_2 += (3*a + b)

print(total_1)
print(total_2)
