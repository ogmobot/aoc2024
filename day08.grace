import "collections" as collections
import "io" as io

method parseInput(fname) {
    var letterlocs:Dictionary[[String, List[[Point]]]] := dictionary.empty
    var maxrow := 0
    var maxcol := 0

    var row := 0
    var col := 0
    def fp = io.open(fname, "r")
    while {fp.hasNext} do {
        def gotch = fp.next
        if (gotch == "\n") then {
            row := row + 1
            col := 0
        } else {
            if (gotch != ".") then {
                //letterlocs[gotch] 
                if (!letterlocs.containsKey(gotch)) then {
                    letterlocs.at(gotch)put(list.empty)
                }
                letterlocs.at(gotch).add(row @ col)
            }
            if (row > maxrow) then {maxrow := row}
            if (col > maxcol) then {maxcol := col}
            col := col + 1
        }
    }
    fp.close

    return object {
        def antennae is readable = letterlocs
        def gridsize is readable = maxrow @ maxcol
    }
}

method allPairs(xs) {
    var result := list.empty
    // Lists are 1-indexed
    for (1..(xs.size)) do { i ->
        for (1..(i - 1)) do { j ->
            result.add([xs.at(j), xs.at(i)])
        }
    }
    return result
}

method outOfBounds(p: Point, bounds: Point) {
    return ((p.x < 0) || (p.y < 0) || (p.x > bounds.x) || (p.y > bounds.y))
}

method solve(inputData) {
    var antinodes:Set[[Point]] := set.empty
    var harmonics:Set[[Point]] := set.empty
    inputData.antennae.valuesDo { coords ->
        for (allPairs(coords)) do { pair ->
            def p = pair.at(1)
            def q = pair.at(2)
            def delta = q - p
            if (!outOfBounds(q + delta, inputData.gridsize)) then {
                antinodes.add(q + delta)
            }
            if (!outOfBounds(p - delta, inputData.gridsize)) then {
                antinodes.add(p - delta)
            }
            var trace := q
            while {!outOfBounds(trace, inputData.gridsize)} do {
                harmonics.add(trace)
                trace := trace + delta
            }
            trace := p
            while {!outOfBounds(trace, inputData.gridsize)} do {
                harmonics.add(trace)
                trace := trace - delta
            }
        }
    }
    return object {
        def part1 is readable = antinodes.size
        def part2 is readable = harmonics.size
    }
}

method main(fname) {
    def inputData = parseInput(fname)
    def solution = solve(inputData)
    print(solution.part1)
    print(solution.part2)
}

main("input08.txt")
