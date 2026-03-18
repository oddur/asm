// program.s — Lesson 11: Calculator
//
// Read two numbers from the user, add them, and print the result.
// This combines everything from lessons 01–10.

.global _start
.align 4

// ============================================================
// print_string — write a string to stdout
//   x0 = pointer, x1 = length
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
// print_uint — print an unsigned integer
//   x0 = number
// ============================================================
print_uint:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    mov     x19, x0
    mov     x20, #0

    cbnz    x19, .Lpu_extract
    mov     w21, #0x30
    strb    w21, [sp, #-16]!
    mov     x20, #1
    b       .Lpu_write

.Lpu_extract:
    mov     x1, #10
    udiv    x2, x19, x1
    msub    x3, x2, x1, x19
    add     x3, x3, #0x30
    sub     sp, sp, #16
    strb    w3, [sp]
    add     x20, x20, #1
    mov     x19, x2
    cbnz    x19, .Lpu_extract

.Lpu_write:
    adrp    x21, num_buf@PAGE
    add     x21, x21, num_buf@PAGEOFF
    mov     x22, #0

.Lpu_copy:
    ldrb    w3, [sp]
    add     sp, sp, #16
    strb    w3, [x21, x22]
    add     x22, x22, #1
    subs    x20, x20, #1
    b.ne    .Lpu_copy

    mov     x0, x21
    mov     x1, x22
    bl      print_string

    mov     sp, x29
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// ============================================================
// read_line — read one line from stdin (stops at newline)
//   x0 = buffer, x1 = max bytes
//   Returns: x0 = bytes read (including newline)
// ============================================================
read_line:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    mov     x19, x0             // x19 = buffer pointer
    mov     x20, #0             // x20 = bytes read so far
    mov     x21, x1             // x21 = max bytes

.Lrl_loop:
    cmp     x20, x21            // Reached max?
    b.ge    .Lrl_done

    // read(stdin, buffer + offset, 1)
    mov     x0, #0              // fd = stdin
    add     x1, x19, x20       // buffer + offset
    mov     x2, #1              // read 1 byte
    mov     x16, #3
    svc     #0x80

    cmp     x0, #0              // EOF or error?
    b.le    .Lrl_done

    // Check if we just read a newline
    ldrb    w0, [x19, x20]
    add     x20, x20, #1
    cmp     w0, #0x0A           // '\n'?
    b.ne    .Lrl_loop

.Lrl_done:
    mov     x0, x20             // return bytes read

    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// ============================================================
// parse_uint — convert decimal string to integer
//   x0 = pointer, x1 = length
//   Returns: x0 = number
// ============================================================
parse_uint:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     x2, x0
    mov     x3, x1
    mov     x0, #0
    mov     x4, #0

.Lparse_loop:
    cmp     x4, x3
    b.ge    .Lparse_done
    ldrb    w5, [x2, x4]
    sub     w5, w5, #0x30
    cmp     w5, #9
    b.hi    .Lparse_done
    mov     x6, #10
    mul     x0, x0, x6
    add     x0, x0, x5
    add     x4, x4, #1
    b       .Lparse_loop

.Lparse_done:
    ldp     x29, x30, [sp], #16
    ret

// ============================================================
// prompt_number — print a prompt, read input, parse number
//   x0 = prompt string pointer
//   x1 = prompt string length
//   Returns: x0 = parsed number
// ============================================================
prompt_number:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]    // Save callee-saved regs

    // Print the prompt
    bl      print_string

    // Read input
    adrp    x0, input_buf@PAGE
    add     x0, x0, input_buf@PAGEOFF
    mov     x1, #128
    bl      read_line
    mov     x19, x0             // save byte count

    // Parse the number
    adrp    x0, input_buf@PAGE
    add     x0, x0, input_buf@PAGEOFF
    mov     x1, x19
    bl      parse_uint
    // x0 = the parsed number

    ldp     x19, x20, [sp, #16]    // Restore callee-saved regs
    ldp     x29, x30, [sp], #32
    ret

// ============================================================
// Entry point
// ============================================================
_start:
    // --- Read first number ---
    adrp    x0, prompt1@PAGE
    add     x0, x0, prompt1@PAGEOFF
    mov     x1, #21
    bl      prompt_number
    mov     x19, x0             // x19 = first number

    // --- Read second number ---
    adrp    x0, prompt2@PAGE
    add     x0, x0, prompt2@PAGEOFF
    mov     x1, #21
    bl      prompt_number
    mov     x20, x0             // x20 = second number

    // --- Print: "a + b = sum" ---
    // Print first number
    mov     x0, x19
    bl      print_uint

    // Print " + "
    adrp    x0, plus_sign@PAGE
    add     x0, x0, plus_sign@PAGEOFF
    mov     x1, #3
    bl      print_string

    // Print second number
    mov     x0, x20
    bl      print_uint

    // Print " = "
    adrp    x0, equals_sign@PAGE
    add     x0, x0, equals_sign@PAGEOFF
    mov     x1, #3
    bl      print_string

    // Compute and print the sum
    add     x0, x19, x20
    bl      print_uint
    bl      print_newline

    // Exit
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
prompt1:        .ascii  "Enter first number:  "
prompt2:        .ascii  "Enter second number: "
plus_sign:      .ascii  " + "
equals_sign:    .ascii  " = "
newline:        .ascii  "\n"
num_buf:        .space  20
input_buf:      .space  128
