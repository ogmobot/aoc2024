with open("input04.txt") as fp:
    lines = [line.strip() for line in fp]

lines_ = """MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX""".split("\n")

grid = {}
for r, line in enumerate(lines):
    for c, symbol in enumerate(line):
        grid[(r, c)] = symbol

total = 0
for key in grid.keys():
    r, c = key
    w = f"{grid.get((r, c))}{grid.get((r+1, c))}{grid.get((r+2, c))}{grid.get((r+3, c))}"
    if w == "XMAS" or w == "SAMX":
        total += 1
    w = f"{grid.get((r, c))}{grid.get((r, c+1))}{grid.get((r, c+2))}{grid.get((r, c+3))}"
    if w == "XMAS" or w == "SAMX":
        total += 1
    w = f"{grid.get((r, c))}{grid.get((r+1, c+1))}{grid.get((r+2, c+2))}{grid.get((r+3, c+3))}"
    if w == "XMAS" or w == "SAMX":
        total += 1
    w = f"{grid.get((r, c))}{grid.get((r+1, c-1))}{grid.get((r+2, c-2))}{grid.get((r+3, c-3))}"
    if w == "XMAS" or w == "SAMX":
        total += 1
print(total)

total = 0
for key in grid.keys():
    if grid[key] == "A":
        r, c = key
        a = f"{grid.get((r + 1, c - 1))}{grid.get((r - 1, c + 1))}"
        b = f"{grid.get((r + 1, c + 1))}{grid.get((r - 1, c - 1))}"
        if (a == "MS" or a == "SM") and (b == "MS" or b == "SM"):
            total += 1

print(total)
