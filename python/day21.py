import heapq
import time
import functools
import itertools

lines ="""279A
286A
508A
463A
246A""".split("\n")
lines_ = """029A
980A
179A
456A
379A""".split("\n")

KEYPAD_NUM = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    [None, '0', 'A']
]
KEYPAD_DIR = [
    [None, '^', 'A'],
    ['<', 'v', '>']
]

# TODO make this programatically
EDGEMAP = {
    ('A', 'A'): ('AA',),
    ('A', '<'): ('Av<<A', 'A<v<A'),
    ('A', 'v'): ('A<vA', 'Av<A'),
    ('A', '>'): ('AvA',),
    ('A', '^'): ('A<A',),

    ('<', 'A'): ('A>>^A', 'A>^>A'),
    ('<', '<'): ('AA',),
    ('<', 'v'): ('A>A',),
    #('<', '>'): ('A>>A'),
    ('<', '^'): ('A>^A',),

    ('v', 'A'): ('A^>A', 'A>^A'),
    ('v', '<'): ('A<A',),
    ('v', 'v'): ('AA',),
    ('v', '>'): ('A>A',),
    #('v', '^'): ('A^A'),

    ('>', 'A'): ('A^A',),
    #('>', '<'): ('A<<A'),
    ('>', 'v'): ('A<A',),
    ('>', '>'): ('AA',),
    ('>', '^'): ('A^<A', 'A<^A'),

    ('^', 'A'): ('A>A',),
    ('^', '<'): ('Av<A',),
    #('^', 'v'): ('AvA'),
    ('^', '>'): ('Av>A','A>vA'),
    ('^', '^'): ('AA',),
}

def get_coord(value): # numeric only
    for r, line in enumerate(KEYPAD_NUM):
        for c, symbol in enumerate(line):
            if symbol == value:
                return (r, c)
    #print(keypad, value)
    raise ValueError("Couldn't find coord")
    return None

def find_sequences(start, target):
    #print('finding sequence', target)
    results = [[]]
    for character in list(target):
        #print(character)
        end = get_coord(character)
        #print(paths_to(keypad, start, end))
        next_results = []
        for r in results:
            for p in paths_to(start, end):
                next_results.append(r + list(p) + ['A'])
        results = next_results
        start = end
    return results

def valid_coord(x):
    r, c = x
    if r >= 0 and r < len(KEYPAD_NUM):
        if c >= 0 and c < len(KEYPAD_NUM[r]):
            if keypad[r][c] != None:
                return True
    return False

def valid_sequence(is_numeric, start, seq):
    if is_numeric:
        keypad = KEYPAD_NUM
    else:
        keypad = KEYPAD_DIR
    r, c = start
    for item in seq:
        if item == '>':
            c += 1
        if item == '<':
            c -= 1
        if item == 'v':
            r += 1
        if item == '^':
            r -= 1
        if keypad[r][c] == None:
            return False
    return True

def paths_to(start, end):
    startr, startc = start
    endr, endc = end
    res = []
    if endr > startr:
        res = res + (['v'] * (endr - startr))
    else:
        res = res + (['^'] * (startr - endr))
    if endc > startc:
        res = res + (['>'] * (endc - startc))
    else:
        res = res + (['<'] * (startc - endc))
    all_forms = set(itertools.permutations(res))
    return [r
            for r in all_forms
            if valid_sequence(True, start, r)]

@functools.cache
def minsteps(edge, layers):
    options = EDGEMAP[edge]
    if layers == 0:
        # Don't need the initial A here
        return min(len(o) for o in options) - 1
    # Alternatively, return 1 and use 3 and 26
    # instead of 2 and 25!
    return min(sum(minsteps(e, layers - 1)
                   for e in itertools.pairwise(o))
               for o in options)

def solve(lines, layers):
    solution = 0
    for line in lines:
        sequences = find_sequences((3, 2), line)
        bestlen = None
        for sequence in sequences:
            minstep = sum(minsteps(e, layers-1) for e in itertools.pairwise(['A']+sequence))
            if bestlen == None or minstep < bestlen:
                bestlen = minstep
        #print(bestedges)
        #print(''.join(bestseq))
        #seqlen = bestedges.total()
        code = int(line.removesuffix('A'))
        #print(bestlen, code)
        solution += (bestlen * code)
    return solution

print(solve(lines, 2))
print(solve(lines, 25))

# first line
# 12, 28, 68

# e.g. should give
# 68
# 60
# 68
# 64
# 64
# (total = 126384)

#     40497593204 is too low
# 130186472584636 too low
# 178746295538656 too high
# 154115708116294 wrong
