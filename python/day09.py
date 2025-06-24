with open("input09.txt") as fp:
    data = fp.read().strip()

data_ = "2333133121414131402"

def merge_frees(frees):
    result = []
    frees.sort()
    #print(frees)
    while frees:
        block = (frees[0][0], 0)
        while frees and frees[0][0] == block[0] + block[1]:
            #print(frees[0])
            block = (block[0], block[1]+frees.pop(0)[1])
        if block[1] > 0:
            result.append(block)
        #print("block", block)
    #print("=>", result)
    return result



files = []
free = []
id_num = 0
disk_index = 0
for i, symbol in enumerate(data):
    if i % 2 == 0:
        files.append((disk_index, id_num, int(symbol)))
        id_num += 1
    else:
        free.append((disk_index, int(symbol)))
    disk_index += int(symbol)

final_disk = []
for file_di, id_num, size in reversed(files):
    # Please be patient...
    print(f"{id_num=}")
    free_index = 0
    while free_index <= len(free):
        if free_index == len(free):
            final_disk.append((file_di, id_num, size))
            break
        free_di, free_len = free[free_index]
        if free_di >= file_di:
            final_disk.append((file_di, id_num, size))
            free_index = len(free) + 1
            break
        if free_len >= size:
            if free_len == size:
                free.pop(free_index)
                free_index -= 1
            else:
                free[free_index] = (free_di + size, free_len - size)
            free.append((file_di, size))
            free = merge_frees(free)
            final_disk.append((free_di, id_num, size))
            break
        free_index += 1

total = 0
for di, id_num, size in final_disk:
    for i in range(size):
        total += ((di + i) * id_num)
print(total)

'''
disk = {}
id_num = 0
disk_index = 0
for i, symbol in enumerate(data):
    if i % 2 == 0:
        for j in range(int(symbol)):
            disk[disk_index + j] = id_num
        id_num += 1
    disk_index += int(symbol)

firstfree = 0
lastspot = disk_index
while firstfree < lastspot:
    while lastspot not in disk:
        lastspot -= 1
    while firstfree in disk:
        firstfree += 1
    if firstfree >= lastspot:
        break
    disk[firstfree] = disk[lastspot]
    del disk[lastspot]

def printdisk(disk):
    toprint = sorted(disk.items())
    for i in range(max(disk.keys())):
        print(disk.get(i, '.'), end="")
    print()

print(sum(i*j for i, j in disk.items()))
'''

# To quote an anonymous post:
# > Legitimately the worst thing I've ever fucking written that actually works
# > I doubt I could ever manage to do anything worse than this, there's nowhere
# > left to dig that could take me any lower.
# -- Anonymous, /g/ #103491036
