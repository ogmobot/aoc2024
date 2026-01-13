import os
import arrays

enum Facing { right down left up }

type Path = Terminal | Loop
struct Terminal { visited []int }
struct Loop {}

struct Grid {
    contents string
    width int
    start_index int
    start_facing Facing
}

fn travel(grid Grid, facing Facing, from_pos int) int {
    // returns -1 if out of bounds
    mut result := 0
    match facing {
        .right { result = from_pos + 1 }
        .down  { result = from_pos + (grid.width + 1) }
        .left  { result = from_pos - 1 }
        .up    { result = from_pos - (grid.width + 1) }
    }
    if result < 0
        || result >= grid.contents.len
        || grid.contents[result] == `\n`
     {
        return -1
    }
    return result
}

fn text_to_grid(text string) Grid {
    mut width := -1
    mut start_index := -1
    mut start_facing := Facing.right
    outerloop: for i in 0 .. text.len {
        match text[i] {
            `\n` {
                if width == -1 {
                    width = i
                }
                if start_index != -1 {
                    break outerloop
                }
            }
            `>`, `v`, `<`, `^` {
                start_index = i
                start_facing = {
                    `>`: Facing.right,
                    `v`: Facing.down,
                    `<`: Facing.left,
                    `^`: Facing.up
                }[text[i]]
                if width != -1 {
                    break outerloop
                }
            }
            else {}
        }
    }
    return Grid{
        contents: text,
        width: width,
        start_index: start_index,
        start_facing: start_facing
    }
}

fn find_path(grid Grid, obstacle ?int) Path {
    mut visited := map[int]([]Facing){}
    mut p := grid.start_index
    mut f := grid.start_facing
    for {
        // record position
        if p in visited {
            if f in visited[p] {
                return Loop {}
            }
            visited[p] << f
        } else {
            visited[p] = [f]
        }
        // take a step
        q := travel(grid, f, p)
        if q == -1 {
            return Terminal{visited.keys()}
        }
        if grid.contents[q] == `#` || q == (obstacle or {-1}) {
            // turn right
            f = {
                Facing.up:    Facing.right,
                Facing.right: Facing.down,
                Facing.down:  Facing.left,
                Facing.left:  Facing.up
            }[f]
        } else {
            p = q
        }
    }
    eprintln("unreachable")
    return Terminal {[]}
}

fn count_loops(grid Grid, obstacle_list []int) int {
    mut total := 0
    for obstacle in obstacle_list {
        if obstacle == grid.start_index {
            continue
        }
        if find_path(grid, ?int(obstacle)) is Loop {
            total += 1
        }
    }
    return total
}

fn main() {
    filename := "input06.txt"
    text := os.read_file(filename) or {
        eprintln("could not read file: ${filename}")
        return
    }
    grid := text_to_grid(text)
    mut obstacle_opts := []int{}

    // Part 1
    p := find_path(grid, none)
    if p is Terminal {
        println(p.visited.len)
        obstacle_opts = unsafe {p.visited}
    } else {
        eprintln("guard already in infinite loop!")
        return
    }

    // Part 2
    nthreads := 8 // fiddling with this may improve performance
    chunk_size := (obstacle_opts.len / nthreads) + 1
    threads := arrays.chunk[int](obstacle_opts, chunk_size).map(
        fn [grid] (obstacles []int) thread int {
            return spawn count_loops(grid, obstacles)
        }
    )
    result := threads.wait()
    println(
        arrays.reduce[int](
            result,
            fn (x int, y int) int {return x + y}
        ) or {-1}
    )
}
