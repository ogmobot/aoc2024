package day22
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:thread"

PRUNE :: 16777216

prng :: proc(seed: int) -> int {
    x := seed
    x = (x ~ (x <<  6)) % PRUNE
    x = (x ~ (x >>  5)) % PRUNE
    x = (x ~ (x << 11)) % PRUNE
    return x
}

worker :: proc(t: ^thread.Thread) {
    dptr := (^int)(t.data)
    x: int = dptr^
    for _ in 1..=2000 {
        x = prng(x)
    }
    dptr^ = x
    return
}

main :: proc() {
    data, err := os.read_entire_file("input22.txt", context.allocator)
    if err != nil {
        fmt.println("Failed to open file.")
        return
    }
    defer delete(data, context.allocator)

    seeds := make([dynamic]int, 0)
    threads := make([dynamic]^thread.Thread, 0)

    text := string(data)
    for line in strings.split_lines_iterator(&text) {
        n, ok := strconv.parse_int(line)
        if ok {
            append(&seeds, n)
        } else {
            fmt.printf("Malformed line: %s\n", line)
        }
    }
    // 1632 lines... that's a lotta threads.

    for seed in &seeds {
        if t := thread.create(worker); t != nil {
            // pass pointers for these ints directly to the threads
            t.user_index = len(threads)
            t.data = &(seeds[t.user_index])
            append(&threads, t)
            thread.start(t)
        }
    }

    total: u64 = 0
    for t in &threads {
        thread.join(t)
        total += (u64)(((^int)(t.data))^)
    }
    fmt.println(total)
    return
}
