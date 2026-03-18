// program.s — Lesson 05: Branching and Conditions
//
// Compare two numbers and print which is larger (or if they're equal).
// Demonstrates: cmp, condition flags, conditional branches, unconditional branch.

.global _start
.align 4

_start:
    // ---- Load two values to compare ----
    mov     x0, #42             // Try changing these!
    mov     x1, #17

    // ---- Compare x0 and x1 ----
    // cmp sets the condition flags (N, Z, C, V) based on x0 - x1
    cmp     x0, x1

    // ---- Branch based on the result ----
    b.eq    equal               // Branch if x0 == x1  (Z flag set)
    b.gt    greater             // Branch if x0 > x1   (signed greater than)
    b       less                // Otherwise, x0 < x1  (unconditional branch)

greater:
    adrp    x1, msg_gt@PAGE
    add     x1, x1, msg_gt@PAGEOFF
    mov     x2, #18
    b       print               // Jump to the print code

less:
    adrp    x1, msg_lt@PAGE
    add     x1, x1, msg_lt@PAGEOFF
    mov     x2, #15
    b       print

equal:
    adrp    x1, msg_eq@PAGE
    add     x1, x1, msg_eq@PAGEOFF
    mov     x2, #22
    b       print

print:
    mov     x0, #1              // fd = stdout
    mov     x16, #4             // syscall = write
    svc     #0x80

    // ---- Exit ----
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
msg_gt: .ascii "First is greater.\n"
msg_lt: .ascii "First is less.\n"
msg_eq: .ascii "They are both equal.\n"
