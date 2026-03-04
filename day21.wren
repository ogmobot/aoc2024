#!/usr/bin/env wren_cli
import "io" for File

var NUMPAD_COORDS = {
    // no button at 30
    00: "7", 01: "8", 02: "9",
    10: "4", 11: "5", 12: "6",
    20: "1", 21: "2", 22: "3",
             31: "0", 32: "A",
}

var KEYPAD_COORDS = {
    // no button at 00
             01: "^", 02: "A",
    10: "<", 11: "v", 12: ">",
}

var allSeqs = Fn.new {|self, grid, from_coord, to_coord|
    // Returns all sequences of <v^> that get you from one button to the other
    if (from_coord == to_coord) return [""]
    var xr = (from_coord / 10).floor
    var xc = from_coord % 10
    var yr = (to_coord / 10).floor
    var yc = to_coord % 10
    var result = []
    if (yr > xr && grid[from_coord + 10] != null) {
        for (subseq in self.call(self, grid, from_coord + 10, to_coord)) {
            result.add("v" + subseq)
        }
    }
    if (yr < xr && grid[from_coord - 10] != null) {
        for (subseq in self.call(self, grid, from_coord - 10, to_coord)) {
            result.add("^" + subseq)
        }
    }
    if (yc > xc && grid[from_coord + 1] != null) {
        for (subseq in self.call(self, grid, from_coord + 1, to_coord)) {
            result.add(">" + subseq)
        }
    }
    if (yc < xc && grid[from_coord - 1] != null) {
        for (subseq in self.call(self, grid, from_coord - 1, to_coord)) {
            result.add("<" + subseq)
        }
    }
    return result
}

var findAllPaths = Fn.new {|coord_dict|
    // Sets up a map of
    // (from + to): [possible, paths, between, them]
    var result = {}
    for (a in coord_dict) {
        if (!(a.key is Num)) continue
        for (b in coord_dict) {
            if (!(b.key is Num)) continue
            if (a.key == b.key) result[a.value + b.value] = [""]
            result[a.value + b.value] = allSeqs.call(
                allSeqs, coord_dict, a.key, b.key
            )
        }
    }
    return result
}

var allPaths = {}
for (kv in findAllPaths.call(KEYPAD_COORDS)) allPaths[kv.key] = kv.value
for (kv in findAllPaths.call(NUMPAD_COORDS)) allPaths[kv.key] = kv.value

class Solver {
    construct new(allPaths) {
        _allPaths = allPaths
        _cache = {}
    }

    pairwiseString(string) {
        //System.print("string=\"%(string)\"")
        return (0...(string.count - 1)).map{|i| string[i...(i+2)]}
    }

    solveEdge(layers, edge) {
        if (layers == 0) return 1
        if (!(_cache[layers])) _cache[layers] = {}
        if (!(_cache[layers][edge])) {
            var steplens = []
            //System.print("edge=%(edge) %(ALL_EDGES[edge])")
            for (path in _allPaths[edge]) {
                var subtotal = 0
                for (oneStep in pairwiseString("A"+path+"A")) {
                    subtotal = subtotal + solveEdge(layers - 1, oneStep)
                }
                steplens.add(subtotal)
            }
            _cache[layers][edge] = steplens.reduce(Fn.new {|x, y|
                return x.min(y)
            })
        }
        return _cache[layers][edge]
    }

    solveCalibur(layers, lines) {
        var total = 0
        for (line in lines) {
            var subtotal = 0
            //System.print("line=%(line)")
            for (pair in pairwiseString("A" + line)) {
                subtotal = subtotal + solveEdge(layers, pair)
            }
            var buttonText = Num.fromString(line[0...(line.count - 1)])
            total = total + (subtotal * buttonText)
        }
        return total
    }
}

var lines = File.read("input21.txt").trim().split("\n")

var s = Solver.new(allPaths)
//System.print(s.solveCalibur(3, ["029A","980A","179A","456A","379A"]))
System.print(s.solveCalibur(3, lines))

var p2 = s.solveCalibur(26, lines)
// display result as integer
var MILLION = 1000000
System.print("%((p2/MILLION).floor)%(p2%MILLION)")
