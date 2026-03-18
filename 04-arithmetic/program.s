// program.s — Lesson 04: Arithmetic
//
// Perform basic math and print single-digit results as ASCII characters.
// We compute: 3 + 4 = 7,  9 - 5 = 4,  3 * 2 = 6,  8 / 2 = 4

.global _start
.align 4

_start:
    // ===================== ADDITION =====================
    mov     x0, #3
    mov     x1, #4
    add     x2, x0, x1         // x2 = 3 + 4 = 7

    // Convert single digit to ASCII and store in output buffer
    // ASCII '0' = 0x30, so digit + 0x30 = ASCII character
    add     x2, x2, #0x30      // x2 = '7'
    adrp    x3, add_result@PAGE
    add     x3, x3, add_result@PAGEOFF
    strb    w2, [x3]            // Store the ASCII digit into the buffer

    // ===================== SUBTRACTION =====================
    mov     x0, #9
    mov     x1, #5
    sub     x2, x0, x1         // x2 = 9 - 5 = 4

    add     x2, x2, #0x30
    adrp    x3, sub_result@PAGE
    add     x3, x3, sub_result@PAGEOFF
    strb    w2, [x3]

    // ===================== MULTIPLICATION =====================
    mov     x0, #3
    mov     x1, #2
    mul     x2, x0, x1         // x2 = 3 * 2 = 6

    add     x2, x2, #0x30
    adrp    x3, mul_result@PAGE
    add     x3, x3, mul_result@PAGEOFF
    strb    w2, [x3]

    // ===================== DIVISION =====================
    mov     x0, #8
    mov     x1, #2
    udiv    x2, x0, x1         // x2 = 8 / 2 = 4 (unsigned divide)

    add     x2, x2, #0x30
    adrp    x3, div_result@PAGE
    add     x3, x3, div_result@PAGEOFF
    strb    w2, [x3]

    // ===================== Print output =====================
    mov     x0, #1
    adrp    x1, output@PAGE
    add     x1, x1, output@PAGEOFF
    mov     x2, #60             // total length of output string
    mov     x16, #4
    svc     #0x80

    // ===================== Exit =====================
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
output:
    .ascii  "3 + 4 = "
add_result:
    .ascii  "0"                 // placeholder — overwritten at runtime
    .ascii  "\n"
    .ascii  "9 - 5 = "
sub_result:
    .ascii  "0"
    .ascii  "\n"
    .ascii  "3 * 2 = "
mul_result:
    .ascii  "0"
    .ascii  "\n"
    .ascii  "8 / 2 = "
div_result:
    .ascii  "0"
    .ascii  "\n"
