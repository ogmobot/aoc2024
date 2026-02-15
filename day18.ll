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

;; "exit" syscall
define void @exit(i64 %exitcode) alwaysinline noreturn {
    call i64 @syscall(i64 60, i64 %exitcode,
                      i64 undef, i64 undef, i64 undef, i64 undef, i64 undef)
    call void asm sideeffect "hlt", ""() noreturn
    unreachable
}

;; "write" syscall
define i64 @write(i64 %fd, ptr %buf, i64 %count) alwaysinline {
    %nbytes = call i64 @syscall(i64 1, i64 %fd, ptr %buf, i64 %count,
                                i64 undef, i64 undef, i64 undef)
    ret i64 %nbytes
}

;;; output function

define void @print_i64(i64 %val) {
    ;; TODO
    ret void
}

;;; main functions

define i64 @main() {
    call void @print_i64(i64 12345)
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
