// program.s — Lesson 03: Registers and Data Types
//
// Demonstrate the ARM64 register file and different data sizes.
// We load values of various sizes, then print a summary line.

.global _start
.align 4

_start:
    // --- Working with 64-bit registers (x) ---
    mov     x0, #1000           // x0 = 1000 (64-bit)
    mov     x1, #2000           // x1 = 2000

    // --- Working with 32-bit registers (w) ---
    // w0-w30 are the lower 32 bits of x0-x30.
    // Writing to w0 zeroes the upper 32 bits of x0.
    mov     w2, #255            // w2 = 255 (32-bit), x2 upper bits = 0

    // --- Moving between registers ---
    mov     x3, x0              // x3 = copy of x0 (1000)

    // --- Loading large immediates with movz/movk ---
    // mov can only load 16-bit values. For larger constants, we
    // build them in 16-bit chunks:
    movz    x4, #0xBEEF         // x4 = 0x000000000000BEEF
    movk    x4, #0xDEAD, lsl #16 // x4 = 0x00000000DEADBEEF
    // movz = move with zero (clears register first)
    // movk = move with keep (preserves other bits)

    // --- Loading data from memory ---
    adrp    x5, my_byte@PAGE
    add     x5, x5, my_byte@PAGEOFF
    ldrb    w6, [x5]            // Load 1 byte  -> w6 = 0x41 ('A')

    adrp    x5, my_word@PAGE
    add     x5, x5, my_word@PAGEOFF
    ldr     w7, [x5]            // Load 4 bytes -> w7 = 12345

    adrp    x5, my_quad@PAGE
    add     x5, x5, my_quad@PAGEOFF
    ldr     x8, [x5]            // Load 8 bytes -> x8 = large number

    // --- Print confirmation ---
    mov     x0, #1
    adrp    x1, result@PAGE
    add     x1, x1, result@PAGEOFF
    mov     x2, #30
    mov     x16, #4
    svc     #0x80

    // --- Exit ---
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

// ---- Data section ----
.data

my_byte:    .byte   0x41                // 1 byte:  'A'
my_half:    .short  1024                // 2 bytes: 1024
my_word:    .long   12345               // 4 bytes: 12345
my_quad:    .quad   0x123456789ABCDEF0  // 8 bytes: large number

.align 4    // Re-align after odd-sized data
result:     .ascii  "Registers loaded OK.\n"
