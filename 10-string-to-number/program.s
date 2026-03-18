// program.s — Lesson 10: String to Number
//
// Parse a decimal string from user input into an integer.
// Combines reading input (lesson 09) with printing numbers (lesson 08).

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
    stp     x19, x20, [sp, #16]    // Save callee-saved registers
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
    ldp     x21, x22, [sp, #32]    // Restore callee-saved registers
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// ============================================================
// read_line — read from stdin
//   x0 = buffer, x1 = max
//   Returns: x0 = bytes read
// ============================================================
read_line:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp
    mov     x2, x1
    mov     x1, x0
    mov     x0, #0
    mov     x16, #3
    svc     #0x80
    ldp     x29, x30, [sp], #16
    ret

// ============================================================
// parse_uint — convert decimal ASCII string to integer
//   x0 = pointer to string
//   x1 = length of string (may include trailing newline)
// Returns:
//   x0 = parsed number
//
// Algorithm:
//   result = 0
//   for each character c:
//     if c < '0' or c > '9': stop
//     result = result * 10 + (c - '0')
// ============================================================
parse_uint:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    mov     x2, x0              // x2 = string pointer
    mov     x3, x1              // x3 = length
    mov     x0, #0              // x0 = result (accumulator)
    mov     x4, #0              // x4 = index

.Lparse_loop:
    cmp     x4, x3              // Past end of string?
    b.ge    .Lparse_done

    ldrb    w5, [x2, x4]        // Load next byte

    // Check if it's a digit ('0' = 0x30, '9' = 0x39)
    sub     w5, w5, #0x30       // Convert from ASCII: '0'->0, '1'->1, etc.
    cmp     w5, #9              // If > 9, it wasn't a digit (or was < '0')
    b.hi    .Lparse_done        // Unsigned comparison: also catches negative

    // result = result * 10 + digit
    mov     x6, #10
    mul     x0, x0, x6          // result *= 10
    add     x0, x0, x5          // result += digit

    add     x4, x4, #1          // index++
    b       .Lparse_loop

.Lparse_done:
    ldp     x29, x30, [sp], #16
    ret

// ============================================================
// Entry point
// ============================================================
_start:
    // Prompt for a number
    adrp    x0, prompt@PAGE
    add     x0, x0, prompt@PAGEOFF
    mov     x1, #16
    bl      print_string

    // Read input
    adrp    x0, input_buf@PAGE
    add     x0, x0, input_buf@PAGEOFF
    mov     x1, #128
    bl      read_line
    mov     x19, x0             // x19 = bytes read

    // Parse the string to a number
    adrp    x0, input_buf@PAGE
    add     x0, x0, input_buf@PAGEOFF
    mov     x1, x19
    bl      parse_uint
    mov     x19, x0             // x19 = parsed number

    // Print "You entered: "
    adrp    x0, msg_entered@PAGE
    add     x0, x0, msg_entered@PAGEOFF
    mov     x1, #13
    bl      print_string

    // Print the number
    mov     x0, x19
    bl      print_uint
    bl      print_newline

    // Double it and print
    adrp    x0, msg_doubled@PAGE
    add     x0, x0, msg_doubled@PAGEOFF
    mov     x1, #9
    bl      print_string

    mov     x0, x19
    add     x0, x0, x19        // double it
    bl      print_uint
    bl      print_newline

    // Square it and print
    adrp    x0, msg_squared@PAGE
    add     x0, x0, msg_squared@PAGEOFF
    mov     x1, #9
    bl      print_string

    mul     x0, x19, x19       // square it
    bl      print_uint
    bl      print_newline

    // Exit
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
prompt:         .ascii  "Enter a number: "
msg_entered:    .ascii  "You entered: "
msg_doubled:    .ascii  "Doubled: "
msg_squared:    .ascii  "Squared: "
newline:        .ascii  "\n"
num_buf:        .space  20
input_buf:      .space  128
