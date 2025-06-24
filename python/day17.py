import heapq
import functools
import re
import random
from time import sleep

with open("input17.txt") as fp:
    lines = [line.strip() for line in fp]

reg_a = int(re.search(r'\d+', lines[0]).group(0))
reg_b = int(re.search(r'\d+', lines[1]).group(0))
reg_c = int(re.search(r'\d+', lines[2]).group(0))
prog = [int(x) for x in lines[4].split(" ")[1].split(",")]

def run(regs, prog):
    A = 0
    B = 1
    C = 2
    ip = 0
    output = []
    while 0 <= ip and ip < len(prog):
        instruction = prog[ip]
        literal_operand = prog[ip + 1]
        operand = {
            4: regs[A],
            5: regs[B],
            6: regs[C]
        }.get(literal_operand, literal_operand)
        ip += 2
        if instruction == 0:
            # adv
            regs[A] //= (2**operand)
        elif instruction == 1:
            # bxl
            regs[B] ^= literal_operand
        elif instruction == 2:
            # bst
            regs[B] = operand % 8
        elif instruction == 3:
            # jnz
            if regs[A] != 0:
                ip = literal_operand
        elif instruction == 4:
            # bxc
            regs[B] ^= regs[C]
        elif instruction == 5:
            # out
            output.append(operand % 8)
        elif instruction == 6:
            # bdv
            regs[B] = regs[A] // (2**operand)
        elif instruction == 7:
            # cdv
            regs[C] = regs[A] // (2**operand)
    return output

output = run([reg_a, reg_b, reg_c], prog)
print(",".join(str(x) for x in output))

# regs[A] encodes the program output somehow

def output_triples(n):
    buffer = []
    while n > 0:
        buffer.insert(0, n % 8)
        n //= 8
    print(' '.join(str(x) for x in buffer))

def dist_to_solution(output):
    while len(output) < len(prog):
        output = output + [9999]
    return sum(abs(a - b) for a, b in zip(prog, output))

def solve():
    b8digits = [1 for _ in range(16)]
    bignum = sum((n << (3 * i)) for i, n in enumerate(b8digits))
    output = run([bignum, 0, 0], prog)
    while output != prog:
        for _ in range(3):
            b8digits[random.randint(0, 15)] = random.randint(0, 3)
        for i in range(len(prog)):
            best = 1e12
            bestdigit = -1
            for option in range(8):
                b8digits[i] = option
                bignum = sum((n << (3 * i)) for i, n in enumerate(b8digits))
                output = run([bignum, 0, 0], prog)
                if dist_to_solution(output) < best:
                    best = dist_to_solution(output)
                    bestdigit = option
            b8digits[i] = bestdigit
        bignum = sum((n << (3 * i)) for i, n in enumerate(b8digits))
        output = run([bignum, 0, 0], prog)
        #print(prog, "prog")
        #print(output, "output")
        bignum = sum((n << (3 * i)) for i, n in enumerate(b8digits))
        #print(bignum)
        #sleep(0.1)
    #print(b8digits)
    bignum = sum((n << (3 * i)) for i, n in enumerate(b8digits))
    print(bignum)

solve()

# Better solution would be increment b8 digits (MOST significant bit first)
# and lock them in place as the *final* output number changes.

'''
nums = [0 for _ in range(16)]
while True:
    pos, val = input("> ").split()
    pos, val = int(pos), int(val)
    nums[pos] = val
    bignum = sum((n << (3 * i)) for i, n in enumerate(nums))
    print(bignum)
    output_triples(bignum)
    output = run([bignum, 0, 0], prog)
    print(' '.join(str(x) for x in output), "<= output")
'''
# not 26400239659562
