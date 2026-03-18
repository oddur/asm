// program.s — Lesson 02: Hello World
//
// Print a message to the terminal, then exit.

.global _start
.align 4

_start:
    // --- write(stdout, message, 14) ---
    mov     x0, #1              // arg1: file descriptor 1 = stdout
    adrp    x1, message@PAGE    // arg2 (part 1): page address of our string
    add     x1, x1, message@PAGEOFF  // arg2 (part 2): add offset within the page
    mov     x2, #14             // arg3: number of bytes to write
    mov     x16, #4             // syscall number 4 = write
    svc     #0x80               // invoke the kernel

    // --- exit(0) ---
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data section ----
.data
message:
    .ascii  "Hello, ARM64!\n"
