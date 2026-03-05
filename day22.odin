package day22
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:thread"

THREAD_COUNT :: 8

soln_data :: struct {
    seed: int,
    seqs: map[int]int
}

encode_seq :: proc(a, b, c, d: int) -> int {
    return ((a + 10) * 20 * 20 * 20
          + (b + 10) * 20 * 20
          + (c + 10) * 20
          + (d + 10))
}

PRUNE :: 16777216
prng :: proc(seed: int) -> int {
    x := seed
    x = (x ~ (x <<  6)) % PRUNE
    x = (x ~ (x >>  5)) % PRUNE
    x = (x ~ (x << 11)) % PRUNE
    return x
}

worker :: proc(t: thread.Task) {
    ptr := cast(^soln_data)(t.data)
    x := ptr.seed
    x0: int = ---    // oldest
    x1: int = ---
    x2: int = ---
    x3: int = ---
    x4: int = x % 10 // newest
    for i in 1..=2000 {
        x = prng(x)
        x0 = x1
        x1 = x2
        x2 = x3
        x3 = x4
        x4 = x % 10
        if i >= 4 {
            key := encode_seq(x1-x0, x2-x1, x3-x2, x4-x3)
            if !(key in ptr.seqs) {
                ptr.seqs[key] = x4
            }
        }
    }
    ptr.seed = x
    return
}

main :: proc() {
    data, err := os.read_entire_file("input22.txt", context.allocator)
    if err != nil {
        fmt.println("Failed to open file.")
        return
    }
    defer delete(data, context.allocator)

    values := make([dynamic]soln_data, 0)
    text := string(data)
    for line in strings.split_lines_iterator(&text) {
        n, ok := strconv.parse_int(line)
        if ok {
            data_chunk: soln_data = {seed = n, seqs = make(map[int]int)}
            defer delete(data_chunk.seqs)
            append(&values, data_chunk)
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

    last_seed_total: i64 = 0
    all_seq_totals := make(map[int]int)
    defer delete(all_seq_totals)
    best_profit := 0

    for chunk in &values {
        last_seed_total += cast(i64) chunk.seed
        for k, v in chunk.seqs {
            if !(k in all_seq_totals) {
                all_seq_totals[k] = 0
            }
            //fmt.printf("k=%d, v=%d, seq_total=%d\n", k, v, all_seq_totals[k])
            all_seq_totals[k] += v
            if all_seq_totals[k] > best_profit {
                best_profit = all_seq_totals[k]
            }
        }
    }
    fmt.println(last_seed_total)
    fmt.println(best_profit)
    return
}
