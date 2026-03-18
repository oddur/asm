// program.s — Lesson 09: Reading Input
//
// Read a line from stdin and echo it back.
// Demonstrates: read syscall, input buffers, handling the return value.

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
// read_line — read from stdin into a buffer
//   x0 = buffer pointer
//   x1 = max bytes to read
// Returns:
//   x0 = number of bytes actually read (0 = EOF, -1 = error)
// ============================================================
read_line:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // read(stdin, buffer, count)
    mov     x2, x1              // arg3: max count
    mov     x1, x0              // arg2: buffer
    mov     x0, #0              // arg1: fd 0 = stdin
    mov     x16, #3             // syscall 3 = read
    svc     #0x80
    // x0 now contains the number of bytes read (or negative on error)

    ldp     x29, x30, [sp], #16
    ret

// ============================================================
// Entry point
// ============================================================
_start:
    // Print prompt
    adrp    x0, prompt@PAGE
    add     x0, x0, prompt@PAGEOFF
    mov     x1, #16
    bl      print_string

    // Read user input
    adrp    x0, input_buf@PAGE
    add     x0, x0, input_buf@PAGEOFF
    mov     x1, #128            // max 128 bytes
    bl      read_line

    // Save the byte count
    mov     x19, x0             // x19 = bytes read

    // Check for error or EOF
    cmp     x19, #0
    b.le    exit

    // Print "You said: "
    adrp    x0, echo_prefix@PAGE
    add     x0, x0, echo_prefix@PAGEOFF
    mov     x1, #10
    bl      print_string

    // Print what the user typed (including the newline they pressed)
    adrp    x0, input_buf@PAGE
    add     x0, x0, input_buf@PAGEOFF
    mov     x1, x19             // length = bytes read
    bl      print_string

exit:
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
prompt:     .ascii  "Type something: "
echo_prefix:.ascii  "You said: "
input_buf:  .space  128         // 128-byte input buffer
