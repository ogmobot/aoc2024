import re

with open("input03.txt") as fp:
    text = fp.read()

'''
ms = re.findall(r"mul\((\d\d?\d?),(\d\d?\d?)\)", text) 
print(sum(int(a)*int(b) for a, b in ms))

ms = re.findall(r"(do\(\))|(don't\(\))|mul\((\d\d?\d?),(\d\d?\d?)\)", text)
for m in ms:
    if m[0]: # do
        enable = True
    elif m[1]: # don't
        enable = False
    elif enable:
        total += int(m[2]) * int(m[3])
print(total)
'''

total_1 = 0
total_2 = 0
enable = 1
for m in re.finditer(
    r"(do\(\))|(don't\(\))|mul\((\d\d?\d?),(\d\d?\d?)\)",
    text
):
    if m.group(1): # do
        enable = 1
    elif m.group(2): # don't
        enable = 0
    else:
        product = int(m.group(3)) * int(m.group(4))
        total_1 += product
        total_2 += (enable * product)
print(total_1)
print(total_2)
