def diffs(vals):
    '''
    return [vals[i+1]-vals[i] for i in range(len(vals)-1)]
    '''
    return [b - a for a, b in zip(vals, vals[1:])]

def is_safe(ds):
    '''
    if all(d > 0 for d in ds) or all(d < 0 for d in ds):
        if (min(abs(d) for d in ds) >= 1) and (max(abs(d) for d in ds) <= 3):
            return True
    '''
    return all(1 <= d <= 3 for d in ds) or all(-3 <= d <= -1 for d in ds)

with open("input02.txt") as fp:
    lines = [line.strip() for line in fp]

safe = 0
safeish = 0
for line in lines:
    vals = [int(x) for x in line.split()]
    if is_safe(diffs(vals)):
        safe += 1
        safeish += 1
    else:
        for i in range(len(vals)):
            new_vals = vals[:i] + vals[i+1:]
            #print(new_vals)
            if is_safe(diffs(new_vals)):
                #print(f"removed [{i}]={vals[i]}")
                safeish += 1
                break
        # A faster way would be determining how many errors
        # appear in the list of diffs; iff there's exactly one,
        # and it can be removed by combining it with a adjacent
        # diff, or removing it if it's the first/last diff, then
        # the list is safeish.
print(safe)
print(safeish)