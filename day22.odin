package day22
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:thread"

THREAD_COUNT :: 8

PRUNE :: 16777216
prng :: proc(seed: int) -> int {
    x := seed
    x = (x ~ (x <<  6)) % PRUNE
    x = (x ~ (x >>  5)) % PRUNE
    x = (x ~ (x << 11)) % PRUNE
    return x
}

worker :: proc(t: thread.Task) {
    dptr := cast(^int)(t.data)
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

    values := make([dynamic]int, 0)
    text := string(data)
    for line in strings.split_lines_iterator(&text) {
        n, ok := strconv.parse_int(line)
        if ok {
            append(&values, n)
        } else {
            fmt.printf("Malformed line: %s\n", line)
        }
    }

    pool: thread.Pool
    thread.pool_init(&pool, context.allocator, THREAD_COUNT)
    // DO NOT USE CONTEXT.ALLOCATOR AFTER THIS POINT.
    thread.pool_start(&pool)
    defer thread.pool_destroy(&pool)

    for i in 0..<len(values) {
        thread.pool_add_task(&pool,
            runtime.nil_allocator(),
            worker,
            &(values[i]),
            i
        )
    }
    thread.pool_finish(&pool)

    total: u64 = 0
    for x in &values {
        total += cast(u64) x
    }
    fmt.println(total)
    return
}
