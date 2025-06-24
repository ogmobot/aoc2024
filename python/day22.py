import itertools
import collections

with open("input22.txt") as fp:
    vals = [int(line) for line in fp]

#vals = [1, 2, 3, 2024]

PRUNE = 16777216
def prng(x):
    while True:
        x = (x ^ (x <<  6)) % PRUNE
        x = (x ^ (x >>  5)) % PRUNE
        x = (x ^ (x << 11)) % PRUNE
        yield x

seqdata = [] # stores {(1,-1,1,2): 6, ...} for each val

total = 0
for val in vals:
    seq = [x for _, x in zip(range(2000), prng(val))]
    total += seq[-1]
    deltas = [(b % 10) - (a % 10) for a, b in itertools.pairwise(seq)]
    res = collections.defaultdict(int)
    for j in range(len(deltas) - 4):
        key = tuple(deltas[j:j+4])
        if key not in res:
            res[key] = (seq[j+4] % 10)
    seqdata.append(res)
print(total)

all_keys = set()
for data in seqdata:
    all_keys |= set(data.keys())
solution = sorted(all_keys,
                  key=(lambda subseq: sum(data[subseq] for data in seqdata)),
                  reverse=True)
best_seq = solution[0]
print(sum(data[best_seq] for data in seqdata))

# 1576 too high
