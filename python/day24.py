import random

class Wire:
    def __init__(self, database, values, line):
        words = line.split()
        self.database = database
        self.values = values
        self.name = words[4]
        self.operator = words[1]
        self.lparent = words[0]
        self.rparent = words[2]
    def eval(self):
        if self.name not in self.values:
            if self.database == None:
                raise ValueError(f"attempted to eval value-only identifier {self.name}")
            lpar = database[self.lparent]
            rpar = database[self.rparent]
            if self.operator == "AND":
                self.values[self.name] = (lpar.eval() and rpar.eval())
            elif self.operator == "OR":
                self.values[self.name] = (lpar.eval() or rpar.eval())
            elif self.operator == "XOR":
                self.values[self.name] = (lpar.eval() != rpar.eval())
            else:
                raise ValueError(f"unknown operator ({self.operator})")
        return self.values[self.name]
    def __repr__(self):
        return f"Wire({self.name} <- {self.lparent} {self.operator} {self.rparent})"

with open("input24.txt") as fp:
    sections = fp.read().strip().split("\n\n")

database = {}
values = {}
for line in sections[0].split("\n"):
    identifier, value = line.split(": ")
    database[identifier] = Wire(None, values, f"ERROR ERROR ERROR ERROR {identifier}")
    values[identifier] = (value == "1")
for line in sections[1].split("\n"):
    words = line.split()
    database[words[4]] = Wire(database, values, line)

def addup():
    digit = 0
    total = 0
    identifier = "z00"
    while identifier in database:
        res = database[identifier].eval()
        total |= (int(res) << digit)
        digit += 1
        identifier = "z" + str(digit).zfill(2)
    return total

def all_errors(a, b):
    result = []
    i = 0
    while a > 0 and b > 0:
        if ((a % 2) != (b % 2)):
            result.append(i)
        a >>= 1
        b >>= 1
        i += 1
    return result

# part 1
res = addup()
print(res)

# part 2
x = sum((int(values["x" + str(i).zfill(2)]) << i) for i in range(45))
y = sum((int(values["y" + str(i).zfill(2)]) << i) for i in range(45))
error_locations = all_errors(res, x + y)

lines = sections[1].split("\n")
# Assumptions:
# Every carry should be populated by OR (that is, CCC <- AAA OR BBB)
# and zNN should never be a carry!
# The inputs for these carries should be the result of an AND gate.
carries = set()
input_to_carries = set()
for line in lines:
    if line.split()[1] == "OR":
        carries.add(line.split()[4])
        input_to_carries.add(line.split()[0])
        input_to_carries.add(line.split()[2])
for line in sections[1].split("\n"):
    if line.split()[4] in input_to_carries:
        if line.split()[1] != "AND":
            print("input to carry not preceded by AND", line)
# Every zNN should be populated by XOR (that is, zNN <- AAA XOR BBB)
# and one of AAA/BBB should be a carry. AAA/BBB should NOT be raw x/y bits.
for line in lines:
    if line.split()[4].startswith("z"):
        if line.split()[1] != "XOR":
            print("not XOR!", line)
'''
        if line.split()[0] not in carries and line.split()[2] not in carries:
            print("\tno carries:", line)
        else:
            if line.split()[0] in carries:
                print(f"\tcarry is 0:{line.split()[0]}")
            else:
                print(f"\tcarry is 1:{line.split()[2]}")
'''
def find_all(phrase):
    print("\n".join([line for line in lines if phrase in line]))

# Use this to draw logic gates!

# Expect this structure:
#
# c00 -------<-> XOR ---------- z02
#             X
# x01<-> XOR <-> AND -\
#     X                \
# y01<-> AND -----------> OR -- c01

# Call all_errors(x + y, z) to determine which bits to start looking at.
# Trace forward from x01, y01 and backwards from z02 to determine which
# wires' outputs have been swapped. All swapped pairs are confined to the
# same full adder. Checking the "carries" and "input_to_carries" might help.

SWAPS = []
SWAPS.append(("z37", "dtv"))
SWAPS.append(("vvm", "dgr"))
SWAPS.append(("fgc", "z12"))
SWAPS.append(("mtj", "z29"))

values.clear()
for line in sections[0].split("\n"):
    identifier, value = line.split(": ")
    database[identifier] = Wire(None, values, f"ERROR ERROR ERROR ERROR {identifier}")
    values[identifier] = (value == "1")
for line in sections[1].split("\n"):
    words = line.split()
    database[words[4]] = Wire(database, values, line)

for a, b in SWAPS:
    database[a], database[b] = database[b], database[a]
z = addup()
print("old", error_locations)
print("new", all_errors(x + y, z))

soln = []
for a, b in SWAPS:
    soln.append(a)
    soln.append(b)
soln.sort()
print(",".join(soln))
