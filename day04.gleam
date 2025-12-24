import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

fn cartesian_product(xs: List(_), ys: List(_)) -> List(#(_, _)) {
    list.flat_map(xs, fn (x) {list.map(ys, fn (y) {#(x, y)})})
}

fn string_to_grid(
    data: String,
    grid: dict.Dict(#(Int, Int), String),
    row: Int, col: Int
) -> dict.Dict(#(Int, Int), String) {
    let car_cdr = string.pop_grapheme(data)
    // "There is notable overhead on this function"
    case car_cdr {
        Error(_)            -> grid // empty string
        Ok(#("\n", rest))   -> string_to_grid(rest, grid, row + 1, 0)
        Ok(#(x,    rest))   -> string_to_grid(rest, grid, row, col + 1)
                                |> dict.insert(#(row, col), x)
    }
}

fn check_word(
    grid: dict.Dict(#(Int, Int), String),
    word: List(String),
    r: Int, c: Int,
    dr: Int, dc: Int
) -> Bool {
    // Assert (or not) that a particular word lies at a particular
    // orientation within the grid.
    case word, dict.get(grid, #(r, c)) {
        [], _       -> True  // no letters left (base recursion case)
        _, Error(_) -> False // word goes out of grid
        [car, ..cdr], Ok(x) if car == x -> { // next letter matches
            check_word(grid, cdr, r+dr, c+dc, dr, dc)
        }
        _, _        -> False // next letter doesn't match
    }
}

fn wordsearch(grid: dict.Dict(#(Int, Int), String), xmas: String) -> Int {
    let xmas_list = string.to_graphemes(xmas)
    let dirs = cartesian_product([-1, 0, 1], [-1, 0, 1])
    let assert Ok(#(maxr, maxc)) = list.max(
        dict.keys(grid),
        fn (a, b) {int.compare(a.0 + a.1, b.0 + b.1)}
    )
    list.map(dirs, fn (dir) {
        let #(dr, dc) = dir
        let rows_cols = cartesian_product(
            list.range(0, maxr),
            list.range(0, maxc)
        )
        list.count(rows_cols, fn (r_c) {
            let #(r, c) = r_c
            check_word(grid, xmas_list, r, c, dr, dc)
        })
    })
    |> list.fold(0, fn (a, b) {a + b})

}

pub fn main() {
    let assert Ok(data) = simplifile.read(from: "../input04.txt")
    let grid = string_to_grid(data, dict.new(), 0, 0)
    io.println(int.to_string(wordsearch(grid, "XMAS")))
}

