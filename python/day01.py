with open("input01.txt") as fp:
    lines = [l.split() for l in fp]

first = [int(a) for a, b in lines]
second = [int(b) for a, b in lines]
first.sort()
second.sort()

print(sum(abs(first[i] - second[i]) for i in range(len(first))))

score = 0
for item in first:
    score += (item * second.count(item))
print(score)
    
