    .module day25

    .globl _main

    .area RSEG (ABS,DATA)
    .org 0x0000

    .area SSEG
__start__stack:
    .ds 1

    .area HOME (CODE)
__interrupt_vect:
    ljmp __sdcc_gsinit_startup

; SDCC's linker expects these
    .area HOME (CODE)
    .area GSINIT (CODE)
    .area GSFINAL (CODE)
    .area GSINIT (CODE)
    .globl __sdcc_gsinit_startup
    .globl __sdcc_program_startup
    .globl __start__stack
    ljmp __sdcc_program_startup
__sdcc_program_startup:
    ljmp _main

    .area CSEG (CODE)
_main:
    ; Program goes here
    ; Read input
    mov scon, #0x90 ; serial control: mode 01, MCE 0, receiver enable 1
    lcall readserial
    lcall storchar
    ; Compute solution
    ; (TODO)
    ; Write output
    mov scon, #0x80 ; serial control: mode 01, MCE 0, receiver enable 0
    mov a, #0x23
    lcall writeserial
    ret

readserial:
    jnb ri, 0 ; wait here until byte received (ri set)
    mov a, sbuf
    clr ri
    ret

writeserial:
    clr ti
    mov sbuf, a
    jnb ti, 0 ; wait here until byte transmitted (ti set)
    ret

storchar:
    ; During this part of the program:
    ; - A is the character just read from serial input
    ; - R0 is the byte location of data being written
    ; - R1 is the bit location of data being written within R0's byte
    ; - R2 is the newline counter

    ; ascii character to process is in A register
    ; Compare it with period (0x2e), newline (0x0a) and hash (0x23)
    ascii_period    = 0x2e
    ascii_newline   = 0x0a
    ascii_hash      = 0x23
    cjne a, #ascii_hash, storchar_skiphash
    ; found '#'
    mov r2, #0 ; reset newline counter
    mov a, #1
    lcall storinputbit
    ret
storchar_skiphash:
    cjne a, #ascii_period, storchar_skipdot
    ; found '.'
    mov r2, #0 ; reset newline counter
    mov a, #0
    lcall storinputbit
    ret
storchar_skipdot:
    cjne a, #ascii_newline, storchar_eof
    ; found '\n'
    inc r2
    ; TODO increment newline counter
    ; TODO If it's two:
    lcall storinputzeroes
    ; TODO if it's three:
    ; assume EOF
    ret
storchar_eof:
    ; unknown character -- assume EOF indicator
    lcall storinputzeroes
    ret

storinputbit:
    ; TODO append the bit stored in the A register to the input bitarray
    ; and increment input column counter
    ret

storinputzeroes:
    ; TODO append 0 bits until the current byte is finished
    ; (assume input is well-behaved, so that at the point
    ; where this function is called, the 5th byte of the
    ; object has been partially stored)
    ret

    .area DSEG (DATA)

start_of_input_ptr:
    .dw puzzle_input
end_of_input_ptr:
    .dw puzzle_input
puzzle_input:
    ; An array of 5-byte items, each representing a key or lock (see puzzle)
    ; Input contains 500 of these
    .ds 2500
    ; ASlink can't find 2504 consecutive bytes to store this in :(
    ; Arrgh... Most registers within 8051 are 8-bit, so they won't be able to
    ; traverse this array...
; some directives
    ; .db [byte] define byte
    ; .dw [word] define word
    ; .ds [N] reserve N bytes
    ; .ascii /string/ ascii literal
