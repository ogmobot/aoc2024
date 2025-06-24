with open("input07.txt") as fp:
    lines = [line.strip() for line in fp]

lines_ = """190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20""".split("\n")

data = []
for line in lines:
    first, last = line.split(": ")
    data.append((int(first), [int(x) for x in last.split()]))

'''
def equals(result, acc, nums, p2):
    if len(nums) == 0:
        return result == acc
    elif equals(result, nums[0] + acc, nums[1:], p2):
        #print(f"{nums[0]} + ", end="")
        return True
    elif equals(result, nums[0] * acc, nums[1:], p2):
        #print(f"{nums[0]} * ", end="")
        return True
    elif p2 and equals(result, int(str(acc) + str(nums[0])), nums[1:], p2):
        return True
    else:
        return False
'''

def equals(target, nums, predops):
    if len(nums) == 0:
        return (target == 0)
    else:
        for pred, op in predops:
            if pred(target, nums[-1]) and equals(op(target, nums[-1]), nums[:-1], predops):
                return True
        return False

total1 = 0
total2 = 0
predops = [
    ((lambda t, n: str(t).endswith(str(n))), (lambda t, n: t // (10**len(str(n))))),
    ((lambda t, n: t % n == 0),              (lambda t, n: t // n)),
    ((lambda t, n: True),                    (lambda t, n: t - n))
]
for result, nums in data:
    if equals(result, nums, predops[1:]):
        total1 += result
    if equals(result, nums, predops):
        total2 += result
print(total1)
print(total2)

