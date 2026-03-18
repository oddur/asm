// program.s — Lesson 08: Printing Numbers
//
// Convert integers to decimal strings and print them.
// We build a reusable print_uint function.

.global _start
.align 4

// ============================================================
// print_string — write a string to stdout
//   x0 = pointer to string
//   x1 = length
// ============================================================
print_string:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    mov     x2, x1
    mov     x1, x0
    mov     x0, #1
    mov     x16, #4
    svc     #0x80
    ldp     x29, x30, [sp], #16
    ret

// ============================================================
// print_newline
// ============================================================
print_newline:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    adrp    x0, newline@PAGE
    add     x0, x0, newline@PAGEOFF
    mov     x1, #1
    bl      print_string
    ldp     x29, x30, [sp], #16
    ret

// ============================================================
// print_uint — print an unsigned integer in decimal
//   x0 = the number to print
//
// Algorithm:
//   1. Repeatedly divide by 10, push each remainder (digit) onto the stack
//   2. Pop digits and write them (this reverses the order back to normal)
// ============================================================
print_uint:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     x19, x0             // x19 = number to convert
    mov     x20, #0             // x20 = digit count

    // Special case: if number is 0, just print '0'
    cbnz    x19, .Lextract_digits
    mov     w21, #0x30          // '0'
    strb    w21, [sp, #-16]!    // Push '0' onto stack (16-byte aligned)
    mov     x20, #1
    b       .Lwrite_digits

.Lextract_digits:
    // Divide by 10, push remainder as ASCII digit
    mov     x1, #10
    udiv    x2, x19, x1        // x2 = x19 / 10
    msub    x3, x2, x1, x19   // x3 = x19 - (x2 * 10) = remainder
    add     x3, x3, #0x30      // Convert to ASCII
    // Push onto stack
    sub     sp, sp, #16
    strb    w3, [sp]
    add     x20, x20, #1       // digit count++
    mov     x19, x2             // number = quotient
    cbnz    x19, .Lextract_digits

.Lwrite_digits:
    // Now write all digits from stack into a contiguous buffer
    adrp    x21, num_buf@PAGE
    add     x21, x21, num_buf@PAGEOFF
    mov     x22, #0             // buffer index

.Lcopy_loop:
    ldrb    w23, [sp]
    add     sp, sp, #16         // pop (16-byte aligned)
    strb    w23, [x21, x22]     // store digit in buffer
    add     x22, x22, #1
    subs    x20, x20, #1
    b.ne    .Lcopy_loop

    // Print the buffer
    mov     x0, x21             // buffer address
    mov     x1, x22             // length = digit count
    bl      print_string

    mov     sp, x29
    ldp     x29, x30, [sp], #16
    ret

// ============================================================
// Entry point
// ============================================================
_start:
    // Print "42 = "
    adrp    x0, label1@PAGE
    add     x0, x0, label1@PAGEOFF
    mov     x1, #5
    bl      print_string
    mov     x0, #42
    bl      print_uint
    bl      print_newline

    // Print "12345 = "
    adrp    x0, label2@PAGE
    add     x0, x0, label2@PAGEOFF
    mov     x1, #8
    bl      print_string
    mov     x0, #12345
    bl      print_uint
    bl      print_newline

    // Print "0 = "
    adrp    x0, label3@PAGE
    add     x0, x0, label3@PAGEOFF
    mov     x1, #4
    bl      print_string
    mov     x0, #0
    bl      print_uint
    bl      print_newline

    // Print "1000000 = "
    adrp    x0, label4@PAGE
    add     x0, x0, label4@PAGEOFF
    mov     x1, #10
    bl      print_string
    movz    x0, #0x4240         // 1000000 = 0xF4240 (too large for mov)
    movk    x0, #0xF, lsl #16   // Build it in two 16-bit chunks
    bl      print_uint
    bl      print_newline

    // Compute and print: 123 + 456 = 579
    adrp    x0, label5@PAGE
    add     x0, x0, label5@PAGEOFF
    mov     x1, #12
    bl      print_string
    mov     x0, #123
    mov     x1, #456
    add     x0, x0, x1
    bl      print_uint
    bl      print_newline

    // Exit
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
newline:    .ascii  "\n"
num_buf:    .space  20          // Buffer for number conversion (max 20 digits for 64-bit)
label1:     .ascii  "42 = "
label2:     .ascii  "12345 = "
label3:     .ascii  "0 = "
label4:     .ascii  "1000000 = "
label5:     .ascii  "123 + 456 = "
