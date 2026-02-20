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
    %fd = call i64 @open(ptr %fname, i64 0, i64 0)
    ; max file size: 32768
    ; prot_read: 1
    ; map_private: 2
    %contents = call ptr @mmap(i64 0, i64 32768, i64 1, i64 2, i64 %fd, i64 0)
    call i64 @close(i64 %fd)
    ; can still use mapped memory after file is closed
    ret ptr %contents
}

define i64 @unload_file(ptr %contents) {
    ; max file size: 32768
    %errno = call i64 @munmap(ptr %contents, i64 32768)
    ret i64 %errno
}

define void @print_i64(i64 %val) {
    ;; TODO
    ret void
}

define ptr @writeln(ptr %s.orig) {
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

;;; main functions

define i64 @main() {
    call void @print_i64(i64 12345)

    %contents.0 = call ptr @load_file(ptr @input_file)
    ; output first three lines for testing...
    %contents.1 = call ptr @writeln(ptr %contents.0)
    %contents.2 = call ptr @writeln(ptr %contents.1)
    %contents.3 = call ptr @writeln(ptr %contents.2)
    call i64 @unload_file(ptr %contents.0)

    ; stdout = 1
    call i64 @write(i64 1, ptr @msg, i64 15)
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
@output_buffer = private global [8 x i8] c"      \0a\00"

; @READ_ONLY     = 0
; @PROT_READ     = 1
; @PROT_WRITE    = 2
; @MAP_PRIVATE   = 2
; @MAP_ANONYMOUS = 32
; @MAX_FILE_SIZE = 32768
