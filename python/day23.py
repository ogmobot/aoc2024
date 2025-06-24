import heapq

with open("input23.txt") as fp:
    lines = [line.strip() for line in fp]

all_cpus = set()
edges = set()
for line in lines:
    left, right = line.split("-")
    edges.add((left, right))
    edges.add((right, left))
    all_cpus.add(left)
    all_cpus.add(right)

# original version
'''
import time
start_time = time.time()
groups = {2: edges.copy()}
size = 2
added_new = True
while added_new:
    # Be patient... (~40s)
    #print(f"{size=} {len(groups[size])=}")
    size += 1
    groups[size] = set()
    added_new = False
    for group in groups[size - 1]:
        for cpu in all_cpus:
            if cpu in group:
                continue
            if all(Edge(cpu, c) in edges for c in group):
                added_new = True
                groups[size].add(frozenset(group) | {cpu})

print(sum(any(cpu.startswith("t") for cpu in g) for g in groups[3]))
print(",".join(sorted(groups[size-1].pop())))
print(time.time() - start_time)
'''
# faster version

def get_triangles(vertices, edges):
    # Chiba & Nishizeki (1985), but without sorting vertices
    vertices = vertices.copy()
    while vertices:
        v = vertices.pop()
        adjacent = {w for w in vertices if (v, w) in edges}
        for a, b in edges:
            if a > b and a in adjacent and b in adjacent:
                # Checking a > b removes duplicated edges
                yield {v, a, b}

total = 0
for triangle in get_triangles(all_cpus, edges):
    if any(v.startswith("t") for v in triangle):
        total += 1
print(total)


def bron_kerbosch(all_edges, subclique, remaining):
    # Mutates remaining!
    if len(remaining) == 0:
        yield subclique
    for v in remaining.copy():
        yield from bron_kerbosch(
            all_edges,
            subclique | {v},
            {p for p in remaining if (p, v) in all_edges},
        )
        remaining.remove(v)

maximal_cliques = bron_kerbosch(edges, set(), all_cpus.copy())
biggest_clique = set()
for mc in maximal_cliques:
    if len(mc) > len(biggest_clique):
        biggest_clique = mc
print(",".join(sorted(biggest_clique)))

