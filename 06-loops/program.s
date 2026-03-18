// program.s — Lesson 06: Loops
//
// Print a countdown from 9 to 0 using a loop.
// Demonstrates: loop structure, counter management, subs.

.global _start
.align 4

_start:
    // Print the header
    mov     x0, #1
    adrp    x1, header@PAGE
    add     x1, x1, header@PAGEOFF
    mov     x2, #12
    mov     x16, #4
    svc     #0x80

    // ---- Initialize the loop counter ----
    mov     x19, #9             // x19 = counter (start at 9)
                                // We use x19 because it's "callee-saved"
                                // (we'll learn why in lesson 07)

loop:
    // Convert counter to ASCII digit and store in buffer
    add     x20, x19, #0x30    // x20 = ASCII character
    adrp    x21, digit@PAGE
    add     x21, x21, digit@PAGEOFF
    strb    w20, [x21]          // Patch the digit into the output line

    // Print the line: "N\n"
    mov     x0, #1
    adrp    x1, digit@PAGE
    add     x1, x1, digit@PAGEOFF
    mov     x2, #2              // 1 digit + newline
    mov     x16, #4
    svc     #0x80

    // Decrement and loop
    subs    x19, x19, #1        // x19 = x19 - 1, set flags
    b.ge    loop                // If x19 >= 0, keep going

    // Print "Liftoff!"
    mov     x0, #1
    adrp    x1, liftoff@PAGE
    add     x1, x1, liftoff@PAGEOFF
    mov     x2, #9
    mov     x16, #4
    svc     #0x80

    // Exit
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
header:     .ascii  "Countdown!\n\n"
digit:      .ascii  "0\n"
liftoff:    .ascii  "Liftoff!\n"
