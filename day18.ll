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
    ; max file size: 4096
    ; prot_read: 1
    ; map_private: 2
    %contents = call ptr @mmap(i64 0, i64 4096, i64 1, i64 2, i64 %fd, i64 0)
    call i64 @close(i64 %fd)
    ; can still use mapped memory after file is closed
    ret ptr %contents
}

define i64 @unload_file(ptr %contents) {
    ; max file size: 4096
    %errno = call i64 @munmap(ptr %contents, i64 4096)
    ret i64 %errno
}

define void @print_int(i64 %val) {
    ;; TODO
    ret void
}

;;; main functions

define i64 @main() {
    call void @print_i64(i64 12345)

    %contents = call ptr @load_file(ptr @input_file)
    call i64 @unload_file(ptr %contents)

    ; stdout = 1
    call i64 @write(i64 1, ptr @msg, i64 15)
    ret i64 6
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

; @READ_ONLY = alias i64 0
; @PROT_READ = alias i64 1
; @PROT_WRITE = alias i64 2
; @MAP_PRIVATE = alias i64 2
; @MAP_ANONYMOUS = alias i64 32
; @MAX_FILE_SIZE = alias i64 16384
