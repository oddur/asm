// program.s — Lesson 07: The Stack and Functions
//
// Introduce subroutines with bl/ret, stack frames, and the calling convention.
// We create a reusable "print_string" function and call it multiple times.

.global _start
.align 4

// ============================================================
// print_string — write a string to stdout
//   x0 = pointer to string
//   x1 = length
// Clobbers: x0, x1, x2, x16 (caller must not rely on them)
// ============================================================
print_string:
    // Save the link register and frame pointer on the stack
    stp     x29, x30, [sp, #-16]!   // Push FP and LR, decrement SP by 16
    mov     x29, sp                  // Set up frame pointer

    // Shuffle arguments for write(fd, buf, count)
    mov     x2, x1              // arg3: length
    mov     x1, x0              // arg2: buffer pointer
    mov     x0, #1              // arg1: fd = stdout
    mov     x16, #4             // syscall = write
    svc     #0x80

    // Restore and return
    ldp     x29, x30, [sp], #16 // Pop FP and LR, increment SP by 16
    ret                          // Return to caller (jumps to address in x30)

// ============================================================
// print_newline — write a newline character
// ============================================================
print_newline:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    adrp    x0, newline@PAGE
    add     x0, x0, newline@PAGEOFF
    mov     x1, #1
    bl      print_string        // Call our own function!

    ldp     x29, x30, [sp], #16
    ret

// ============================================================
// Entry point
// ============================================================
_start:
    // Call print_string with "Hello from a function!"
    adrp    x0, msg1@PAGE
    add     x0, x0, msg1@PAGEOFF
    mov     x1, #22
    bl      print_string        // Branch with Link — saves return address in x30

    bl      print_newline

    // Call it again with a different message
    adrp    x0, msg2@PAGE
    add     x0, x0, msg2@PAGEOFF
    mov     x1, #31
    bl      print_string

    bl      print_newline

    // Demonstrate saving callee-saved registers
    // Call a function that preserves x19 across the call
    mov     x19, #42            // x19 should survive the function call
    adrp    x0, msg3@PAGE
    add     x0, x0, msg3@PAGEOFF
    mov     x1, #17
    bl      print_string
    bl      print_newline

    // x19 is still 42 here — the function preserved it
    // (If we'd used x0, it would be gone — overwritten by the syscall)

    // Exit
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
msg1:       .ascii  "Hello from a function!"
msg2:       .ascii  "Called the same function twice!"
msg3:       .ascii  "x19 is preserved!"
newline:    .ascii  "\n"
