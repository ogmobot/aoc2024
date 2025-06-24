from collections import defaultdict
from functools import cmp_to_key

with open("input05.txt") as fp:
    text = fp.read().strip()

    text_ = """47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47"""
    
    first, second = text.split("\n\n")

reqs = defaultdict(set)
for line in first.split("\n"):
    a, b = line.split("|")
    reqs[int(b)].add(int(a))

def lt(a, b):
    if (a not in reqs) or (b not in reqs):
        return 0
    elif b in reqs[a]:
        return 1
    elif a in reqs[b]:
        return -1
    return res

total1 = 0
total2 = 0
for update in second.split("\n"):
    #print(update)
    update = [int(x) for x in update.split(",")]
    valid = True
    for i in range(len(update)):
        if (update[i] not in reqs):
            continue
        if any((r in update[i+1:]) for r in reqs[update[i]]):
            valid = False
            break
    if valid:
        #print(update, update[len(update) // 2])
        total1 += update[len(update) // 2]
    else:
        #print(f"fixing {update}...")
        update.sort(key=cmp_to_key(lt))
        #print(update)
        total2 += update[len(update) // 2]

            
print(total1)
print(total2)
