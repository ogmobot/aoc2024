with open("input11.txt") as fp:
    vals = [int(x) for x in fp.read().split()]

vals_ = [125, 17]

def change_once(v):
    result = []
    if v == 0:
        result.append(1)
    else:
        strlen = len(str(v))
        if strlen % 2 == 0:
            result.append(int(str(v)[:strlen//2]))
            result.append(int(str(v)[strlen//2:]))
        else:
            result.append(2024*v)
    return result


cache = {}
def branchlength(val, rem):
    if rem == 0:
        return 1
    if (val, rem) not in cache:
        new_vals = change_once(val)
        cache[(val, rem)] = sum(branchlength(x, rem - 1) for x in new_vals)
    return cache[(val, rem)]

def change_all(vals):
    result = []
    for v in vals:
        result.extend(change_once(v))
    return result

# Easy problem. I lost like 15 min because I didn't realise the original
# version of this mutated vals...
vv = vals
for _ in range(25):
    vv = change_all(vv)

print(len(vv))

print(sum(branchlength(x, 75) for x in vals))

