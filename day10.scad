PATH_START = 0;
PATH_END = 9;

//text = "89010123\n78121874\n87430965\n96549874\n45678903\n32019012\n01329801\n10456732";
<<<INPUT_TEXT_HERE>>>

// Utility functions
function fold(f, xs, acc, i = 0) =
    i >= len(xs)
        ? acc
        : fold(f, xs, f(xs[i], acc), i + 1);

// Parse input

function _readDigit (d) = search(d, "0123456789")[0];
function _buildRow (s, i) =
    i >= len(s) - 1 || s[i] == "\n"
        ? []
        : concat([_readDigit(s[i])], _buildRow(s, i + 1));
function buildGrid (s, i = 0) =
    i >= len(s) - 1
        ? []
        : let (row = _buildRow (s, i))
            concat([row], buildGrid(s, i + len(row) + 1));

grid = buildGrid(text);

// Build graph

function _inBounds(grid, r, c) =
    r >= 0 && c >= 0 && r < len(grid) && c < len(grid[r]);

function _neighboursWithValue(grid, coord, val) =
    [for (delta = [[-1, 0], [1, 0], [0, -1], [0, 1]])
        let (r = coord[0] + delta[0], c = coord[1] + delta[1])
        if (_inBounds(grid, r, c) && grid[r][c] == val)
        [r, c]];

function buildNetwork(grid, network=[]) =
    // nodes are lists of [[selfrow, selfcol], val, [[adjrow, adjcol], ...]]
    [for (row = [0 : len(grid) - 1], col = [0 : len(grid[row]) - 1])
        [
            [row, col],
            grid[row][col],
            _neighboursWithValue(grid, [row, col], grid[row][col] + 1)]];

function findCoordsWithValue(grid, val) =
    [for (row = [0 : len(grid) - 1], col = [0 : len(grid[row]) - 1])
        if (grid[row][col] == val)
        [row, col]];

network = buildNetwork(grid);
trailheads = findCoordsWithValue(grid, PATH_START);

// Part 1

function _appendAll(reglist, lisplist, i = 0) =
    i == len(reglist)
        ? lisplist
        : _appendAll(reglist, [reglist[i], lisplist], i + 1);

function DFS(network, front, visited = []) =
    // Use LISP-style list for DFS stack
    front == []
        ? len([
            for (point = visited)
            if (network[search([point], network)[0]][1] == PATH_END)
            point])
        : (
            let (
                car = front[0],
                cdr = front[1],
                current = network[search([car], network)[0]])
            search([car], visited)[0] == []
                ? DFS(
                    network,
                    _appendAll(current[2], cdr),
                    concat(visited, [current[0]]))
                : DFS(network, cdr, visited));

// Part 2

function _findNode(network, coord, i = 0) =
    // Assumes coord is in the network!
    network[i][0] == coord
        ? network[i]
        : _findNode(network, coord, i + 1);

function _layerContains(layer, coord, i = 0) =
    i >= len(layer)
        ? false
        : (layer[i][0][0] == coord
            ? true
            : _layerContains(layer, coord, i + 1));

function _extendLayer(network, layer, coords, i = 0) =
    i >= len(coords)
        ? layer
        : _extendLayer(
            network,
            (_layerContains(layer, coords[i])
                ? layer
                : concat(layer, [[_findNode(network, coords[i]), 0]])),
            coords,
            i + 1);

function _incrementNodeAmounts(network, layer, coords, amount) =
    [for (pair = _extendLayer(network, layer, coords))
        search([pair[0][0]], coords)[0] == []
            ? pair
            : [pair[0], pair[1] + amount]];

function _iterateUpwards(network, inputLayer, i = 0, outputLayer = []) =
    // inputLayer is [[[coord, value, neighbours], amount], ...]
    i >= len(inputLayer)
        ? (outputLayer[0][0][1] == PATH_END
            ? outputLayer
            : _iterateUpwards(network, outputLayer))
        : (let (node = inputLayer[i][0], amount = inputLayer[i][1])
            _iterateUpwards(
                network,
                inputLayer,
                i + 1,
                _incrementNodeAmounts(network, outputLayer, node[2], amount)));

function countPaths(network) =
    let (outputLayer = _iterateUpwards(
            network,
            [for (trailhead = trailheads) [_findNode(network, trailhead), 1]]))
        fold((function (pair, acc) pair[1] + acc), outputLayer, 0);

// Visualiser

module createModel(network, maxHeight = 2){
    for (node = network) {
        let (
            row = node[0][0],
            col = node[0][1],
            height = node[1],
            neighbours = node[2])
        translate([row, col, 0])
            color([0.0 + (height / 10), 0.2, 1.0 - (height / 10)])
                cube([1, 1, maxHeight * (height + 1)/(PATH_END + 1)]);
    }
}

if (!doModel) {
    scores = [for (trailhead = trailheads) DFS(network, [trailhead, []])];
    echo(fold((function (x, y) x + y), scores, 0));
    echo(countPaths(network));
} else {
    createModel(network);
}
