target triple = "x86_64-pc-linux-gnu"

;; With thanks to Sheafification of G

;;; syscalls

;; syscall wrapper
define i64 @syscall(i64 %call,
                    i64 %rdi, i64 %rsi, i64 %rdx,
                    i64 %r10, i64 %r8, i64 %r9) alwaysinline {
    %rax = call i64 asm sideeffect "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9},~{rcx},~{r11}"
        (i64 %call, i64 %rdi, i64 %rsi, i64 %rdx, i64 %r10, i64 %r8, i64 %r9)
    ret i64 %rax
}

;; "write" syscall (1)
define i64 @write(i64 %fd, ptr %buf, i64 %count) alwaysinline {
    %nbytes = call i64 @syscall(i64 1, i64 %fd, ptr %buf, i64 %count,
                                i64 undef, i64 undef, i64 undef)
    ret i64 %nbytes
}
;; "open" syscall (2)
define i64 @open(ptr %fname, i64 %flags, i64 %mode) alwaysinline {
    %fd = call i64 @syscall(i64 2, ptr %fname, i64 %flags, i64 %mode,
                                i64 undef, i64 undef, i64 undef)
    ret i64 %fd
}

;; "close" syscall (3)
define i64 @close(i64 %fd) alwaysinline {
    %errno = call i64 @syscall(i64 3, i64 %fd,
                        i64 undef, i64 undef, i64 undef, i64 undef, i64 undef)
    ret i64 %errno
}

;; "mmap" syscall (9)
;; (use this instead of read(0))
define ptr @mmap(
    ptr %addr, i64 %len, i64 %prot, i64 %flags, i64 %fd, i64 %offset
) alwaysinline {
    %memory = call ptr @syscall(i64 9, ptr %addr, i64 %len,
                              i64 %prot, i64 %flags, i64 %fd, i64 %offset)
    ret ptr %memory
}

;; "munmap" syscall (11)
define i64 @munmap(ptr %addr, i64 %length) alwaysinline {
    %errno = call i64 @syscall(i64 11, ptr %addr, i64 %length,
                        i64 undef, i64 undef, i64 undef, i64 undef)
    ret i64 %errno
}

;; "exit" syscall (60)
define void @exit(i64 %exitcode) alwaysinline noreturn {
    call i64 @syscall(i64 60, i64 %exitcode,
                      i64 undef, i64 undef, i64 undef, i64 undef, i64 undef)
    call void asm sideeffect "hlt", ""() noreturn
    unreachable
}

;;; input/output functions

define ptr @load_file(ptr %fname) {
    ; read-only: 0
    ; no special flags: 0
    %fd = call i64 @open(ptr %fname, i64 0, i64 0)
    ; OS chooses address: 0
    ; max file size: 32768
    ; prot_read: 1
    ; map_private: 2
    ; backed by fd: %fd
    ; no offset: 0
    %contents = call ptr @mmap(i64 0, i64 32768, i64 1, i64 2, i64 %fd, i64 0)
    call i64 @close(i64 %fd)
    ; note - can still use mapped memory after file is closed
    ret ptr %contents
}

define i64 @unload_file(ptr %contents) {
    ; max file size: 32768
    %errno = call i64 @munmap(ptr %contents, i64 32768)
    ret i64 %errno
}

define ptr @next_line(ptr %line) {
    ; advance to one char beyond next newline
loop.header:
    br label %loop
loop:
    %s = phi ptr [ %line, %loop.header ], [ %s.next, %loop ]
    %s.next = getelementptr i8, ptr %s, i64 1
    %c = load i8, ptr %s, align 1
    %is.nl = icmp eq i8 %c, 10
    br i1 %is.nl, label %done, label %loop
done:
    ret ptr %s.next
}

define void @print_u64(i64 %val.orig) {
    ; I could probably have just done hundreds, tens, ones...
fill.header:
    ; Largest u64 is 20 digits, plus \n \00, plus safety
    %buffer = alloca i8, i64 24, align 1
    %buffer.end  = getelementptr i8, ptr %buffer, i64 23
    %buffer.nl   = getelementptr i8, ptr %buffer.end, i64 -1
    %digit.start = getelementptr i8, ptr %buffer.end, i64 -2
    store i8 10, ptr %buffer.nl
    store i8  0, ptr %buffer.end
    br label %fill
fill:
    %digit = phi ptr [ %digit.start, %fill.header ], [ %digit.next, %fill ]
    %val = phi i64 [ %val.orig, %fill.header ], [ %val.next, %fill ]
    %digit.next = getelementptr i8, ptr %digit, i64 -1
    %val.digit = urem i64 %val, 10
    %val.next  = udiv i64 %val, 10
    ; write digit to buffer
    %val.digit.i8 = trunc i64 %val.digit to i8
    %val.digit.chr = add i8 %val.digit.i8, 48
    store i8 %val.digit.chr, ptr %digit
    %is.zero = icmp eq i64 %val.next, 0
    br i1 %is.zero, label %write, label %fill
write:
    call ptr @write_line(ptr %digit)
    ret void
}

define ptr @write_line(ptr %s.orig) {
loop.header:
    br label %loop
loop:
    %s = phi ptr [ %s.orig, %loop.header ], [ %s.next, %loop ]
    %s.next = getelementptr i8, ptr %s, i64 1
    %c = load i8, ptr %s, align 1
    %is.nl = icmp eq i8 %c, 10
    br i1 %is.nl, label %write, label %loop
write:
    %s.orig.int = ptrtoint ptr %s.orig to i64
    %s.next.int = ptrtoint ptr %s.next to i64
    %len = sub i64 %s.next.int, %s.orig.int
    call i64 @write(i64 1, ptr %s.orig, i64 %len)
    ret ptr %s.next
}

define void @print_grid(ptr %grid.ref) {
    ; assume grid is ascii-encoded
    call i64 @write(i64 1, ptr %grid.ref, i64 5256)
    ret void
}

;;; logic functions

define ptr @setup_grid() {
    ; 1st row: 71 x # then \n (so . is at i = 72-1)
    ; 2nd row: 71 x . then \n (so \n is at i = 144-1)
    ; ...
    ; 73rd row: 72 x #
initzero.header:
    ; OS chooses address: 0
    ; grid is 72x73 (incl. border): 5256
    ; prot_read | prot_write: 1 | 2
    ; map_private | map_anonymous: 2 | 32
    ; not backed by a file: 0
    ; no offset: 0
    %grid.ref = call ptr @mmap(i64 0, i64 5256, i64 3, i64 34, i64 0, i64 0)
    br label %initzero
initzero:
    ; note -- this gets optimised to a memset call, so ld needs -lc argument
    %i = phi i64 [ 0, %initzero.header ], [ %i.inc, %initzero ]
    %grid.i = getelementptr i8, ptr %grid.ref, i64 %i
    store i8 46, ptr %grid.i ; .
    %i.inc = add i64 %i, 1
    %all.zero = icmp eq i64 %i.inc, 5256
    br i1 %all.zero, label %border, label %initzero
border:
    ;something like
    ; for j = 0..72
    ;   create border at grid[ 0][j]
    ;   create border at grid[72][j]
    ;   create border at grid[j+1][71]
    %j = phi i64 [ 0, %initzero ], [ %j.inc, %border ]
    %j.inc = add i64 %j, 1
    %bot.offset = getelementptr i8, ptr %grid.ref, i64 5184 ; 72x72
    %j.72 = mul i64 %j, 72
    %j.72endl = add i64 %j.72, 71
    %grid.topj  = getelementptr i8, ptr %grid.ref,   i64 %j
    %grid.botj  = getelementptr i8, ptr %bot.offset, i64 %j
    %grid.leftj = getelementptr i8, ptr %grid.ref,   i64 %j.72endl
    store i8 35, ptr %grid.topj ; #
    store i8 35, ptr %grid.botj ; #
    store i8 10, ptr %grid.leftj ; \n
    %row.done = icmp eq i64 %j, 71
    br i1 %row.done, label %done, label %border
done:
    ret ptr %grid.ref
}

define i64 @cleanup_grid(ptr %grid.ref) {
    %errno = call i64 @munmap(ptr %grid.ref, i64 5256);
    ret i64 %errno
}

define void @drop_from_line(ptr %line, ptr %grid.start) {
    ;; parse x and y
parse.begin:
    br label %parse_x_digit
parse_x_digit:
    %x.acc = phi i64 [ 0, %parse.begin ], [ %x.next, %parse_x_digit ]
    %x.chr = phi ptr [ %line, %parse.begin ], [ %x.chr.next, %parse_x_digit ]
    %x.chr.next = getelementptr i8, ptr %x.chr, i64 1
    ; dereference x
    %x.c = load i8, ptr %x.chr, align 1
    ; parse digit
    %x.c.value = sub i8 %x.c, 48
    %x.c.value.64 = zext i8 %x.c.value to i64
    ; put into accumulator
    %x.10 = mul i64 %x.acc, 10
    %x.next = add i64 %x.10, %x.c.value.64
    ; if this digit isn't actually a digit, skip to next block
    %x.atleastzero = icmp uge i8 %x.c, 48
    %x.atmostnine  = icmp ult i8 %x.c, 58
    %x.is.digit = and i1 %x.atleastzero, %x.atmostnine
    br i1 %x.is.digit, label %parse_x_digit, label %x.done
x.done:
    ; x.acc contains the value of x
    %y.start = getelementptr i8, ptr %x.chr, i64 1
    br label %parse_y_digit
parse_y_digit:
    %y.acc = phi i64 [ 0, %x.done ], [ %y.next, %parse_y_digit ]
    %y.chr = phi ptr [ %y.start, %x.done ], [ %y.chr.next, %parse_y_digit ]
    %y.chr.next = getelementptr i8, ptr %y.chr, i64 1
    ; dereference y
    %y.c = load i8, ptr %y.chr, align 1
    ; parse digit
    %y.c.value = sub i8 %y.c, 48
    %y.c.value.64 = zext i8 %y.c.value to i64
    ; put into accumulator
    %y.10 = mul i64 %y.acc, 10
    %y.next = add i64 %y.10, %y.c.value.64
    ; if this digit isn't actually a digit, skip to next block
    %y.atleastzero = icmp uge i8 %y.c, 48
    %y.atmostnine  = icmp ult i8 %y.c, 58
    %y.is.digit = and i1 %y.atleastzero, %y.atmostnine
    br i1 %y.is.digit, label %parse_y_digit, label %y.done
y.done:
    ;call void @print_u64(i64 %x.acc)
    ;call void @print_u64(i64 %y.acc)
    ;; calculate index = 72y + x
    %y.72 = mul i64 %y.acc, 72
    %offset = add i64 %y.72, %x.acc
    %obstacle = getelementptr i8, ptr %grid.start, i64 %offset
    store i8 35, ptr %obstacle
    ret void
}

define i64 @bfs(ptr %grid.start) {
    %queue.ref = alloca i32, i64 1024, align 4
    %queue.ref.inc = getelementptr i32, ptr %queue.ref, i64 1
    %queue.head.addr = alloca i64
    %queue.tail.addr = alloca i64
    %ret.val = alloca i64
    store i64 0, ptr %queue.head.addr
    ; push first node
    store i32 0, ptr %queue.ref     ; index
    store i32 0, ptr %queue.ref.inc ; dist
    store i64 2, ptr %queue.tail.addr
    br label %explore
explore:
    %queue.head = load i64, ptr %queue.head.addr, align 8
    %queue.tail = load i64, ptr %queue.tail.addr, align 8
    ;call void @print_u64(i64 %queue.head)
    %exhausted = icmp eq i64 %queue.head, %queue.tail
    br i1 %exhausted, label %ret.fail, label %pop.queue
pop.queue:
    %index.addr = getelementptr i32, ptr %queue.ref, i64 %queue.head
    %dist.addr  = getelementptr i32, ptr %index.addr, i32 1
    %index = load i32, ptr %index.addr, align 4
    %dist  = load i32, ptr %dist.addr, align 4
    %queue.head.inc = add i64 %queue.head, 2
    %queue.head.mod = urem i64 %queue.head.inc, 1024
    store i64 %queue.head.mod, ptr %queue.head.addr, align 8

    ; check/mark if visited
    %loc = getelementptr i8, ptr %grid.start, i32 %index
    %c = load i8, ptr %loc
    %is.valid = icmp eq i8 %c, 46 ; .
    br i1 %is.valid, label %mark.visited, label %explore
mark.visited:
    %c.flagged = or i8 %c, 128
    store i8 %c.flagged, ptr %loc

    %found.exit = icmp eq i32 %index, 5110 ; = 70*72 + 70
    br i1 %found.exit, label %ret.success, label %append.adj
append.adj:
    ; set up values to store and addresses
    %dist.inc = add i32 %dist, 1
    %index.west = sub i32 %index, 1
    %index.east = add i32 %index, 1
    %index.north = sub i32 %index, 72
    %index.south = add i32 %index, 72
    %queue.tail.2 = add i64 %queue.tail, 2
    %queue.tail.2.mod = urem i64 %queue.tail.2, 1024
    %queue.tail.4 = add i64 %queue.tail, 4
    %queue.tail.4.mod = urem i64 %queue.tail.4, 1024
    %queue.tail.6 = add i64 %queue.tail, 6
    %queue.tail.6.mod = urem i64 %queue.tail.6, 1024
    %queue.tail.8 = add i64 %queue.tail, 8
    %queue.tail.8.mod = urem i64 %queue.tail.8, 1024
    %q.t.0 = getelementptr i32, ptr %queue.ref, i64 %queue.tail
    %q.t.1 = getelementptr i32, ptr %q.t.0, i64 1
    %q.t.2 = getelementptr i32, ptr %queue.ref, i64 %queue.tail.2.mod
    %q.t.3 = getelementptr i32, ptr %q.t.2, i64 1
    %q.t.4 = getelementptr i32, ptr %queue.ref, i64 %queue.tail.4.mod
    %q.t.5 = getelementptr i32, ptr %q.t.4, i64 1
    %q.t.6 = getelementptr i32, ptr %queue.ref, i64 %queue.tail.6.mod
    %q.t.7 = getelementptr i32, ptr %q.t.6, i64 1
    store i64 %queue.tail.8.mod, ptr %queue.tail.addr, align 8
    ; store them
    store i32 %index.west,  ptr %q.t.0, align 4
    store i32 %dist.inc,    ptr %q.t.1, align 4
    store i32 %index.east,  ptr %q.t.2, align 4
    store i32 %dist.inc,    ptr %q.t.3, align 4
    store i32 %index.north, ptr %q.t.4, align 4
    store i32 %dist.inc,    ptr %q.t.5, align 4
    store i32 %index.south, ptr %q.t.6, align 4
    store i32 %dist.inc,    ptr %q.t.7, align 4
    br label %explore
ret.success:
    %dist.i64 = zext i32 %dist to i64
    store i64 %dist.i64, ptr %ret.val
    br label %clear.flags
ret.fail:
    store i64 -1, ptr %ret.val
    br label %clear.flags
clear.flags:
    %i = phi i64 [ 0, %ret.success ], [ 0, %ret.fail ], [ %i.inc, %clear.flags ]
    %i.inc = add i64 %i, 1
    %c.uncleared.addr = getelementptr i8, ptr %grid.start, i64 %i
    %c.uncleared = load i8, ptr %c.uncleared.addr, align 1
    %c.cleared = and i8 %c.uncleared, 127
    store i8 %c.cleared, ptr %c.uncleared.addr
    %clear.done = icmp eq i64 %i, 5110
    br i1 %clear.done, label %finally, label %clear.flags
finally:
    %ret = load i64, ptr %ret.val, align 8
    ret i64 %ret
}

;;; main functions

define ptr @part1(ptr %contents, ptr %grid.start) {
    ; returns ptr to next line
drop.header:
    br label %drop
drop:
    %line = phi ptr [ %contents, %drop.header ], [ %line.next, %drop ]
    %counter = phi i64 [ 0, %drop.header ], [ %counter.inc, %drop ]
    %counter.inc = add i64 %counter, 1
    %line.next = call ptr @next_line(ptr %line)
    call void @drop_from_line(ptr %line, ptr %grid.start)
    %is.1kb = icmp eq i64 %counter.inc, 1024
    br i1 %is.1kb, label %findpath, label %drop
findpath:
    %soln = call i64 @bfs(ptr %grid.start)
    call void @print_u64(i64 %soln)
    ret ptr %line.next
}

define i64 @main() {
    ;call void @print_u64(i64 123454321)

    %contents.0 = call ptr @load_file(ptr @input_file)
    ; output first three lines for testing...
    ;%contents.1 = call ptr @write_line(ptr %contents.0)
    ;%contents.2 = call ptr @write_line(ptr %contents.1)
    ;%contents.3 = call ptr @write_line(ptr %contents.2)

    %grid.ref = call ptr @setup_grid()
    ;%grid.2 = call ptr @write_line(ptr %grid.ref)
    ;%grid.3 = call ptr @write_line(ptr %grid.2)
    ;%grid.4 = call ptr @write_line(ptr %grid.3)
    ;call void @print_grid(ptr %grid.ref)
    %grid.start = getelementptr i8, ptr %grid.ref, i64 72

    call void @part1(ptr %contents.0, ptr %grid.start)
    ;call void @print_grid(ptr %grid.ref)

    ; stdout = 1
    ;call i64 @write(i64 1, ptr @msg, i64 15)

    call i64 @unload_file(ptr %contents.0)
    call ptr @cleanup_grid(ptr %grid.ref)
    ret i64 123
}

;; _start function so that C runtime doesn't need to be linked
;; ( /lib/x86_64-linux-gnu/crt1.o )

define void @_start() naked {
    ; clear %rbp
    call void asm sideeffect "", "{rbp}"(i64 0)

    %exitcode = call i64 @main()
    call void @exit(i64 %exitcode)
    unreachable
}

;; constants

@msg = private constant [15 x i8] c"hello, world!\0a\00"
@input_file = private constant [12 x i8] c"input18.txt\00"
