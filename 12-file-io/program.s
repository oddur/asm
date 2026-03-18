// program.s — Lesson 12: File I/O
//
// Read a file and print its contents to stdout.
// Also demonstrates creating and writing to a file.
// Usage: ./program           (reads sample.txt)
//        echo "hi" > test.txt && modify source to read test.txt

.global _start
.align 4

// ============================================================
// print_string — write to stdout
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
// Entry point
// ============================================================
_start:
    // ==========================================
    // PART 1: Create a file and write to it
    // ==========================================

    adrp    x0, msg_creating@PAGE
    add     x0, x0, msg_creating@PAGEOFF
    mov     x1, #18
    bl      print_string

    // open("sample.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644)
    //   O_WRONLY = 0x0001
    //   O_CREAT  = 0x0200
    //   O_TRUNC  = 0x0400
    //   flags = 0x0601
    adrp    x0, filename@PAGE
    add     x0, x0, filename@PAGEOFF
    mov     x1, #0x0601         // O_WRONLY | O_CREAT | O_TRUNC
    mov     x2, #0x1A4          // 0644 octal = 0x1A4 = rw-r--r--
    mov     x16, #5             // syscall 5 = open
    svc     #0x80

    // Check for error (negative return = error)
    cmp     x0, #0
    b.lt    open_error

    mov     x19, x0             // x19 = file descriptor

    // Write content to the file
    // write(fd, content, length)
    mov     x0, x19             // fd
    adrp    x1, file_content@PAGE
    add     x1, x1, file_content@PAGEOFF
    mov     x2, #43             // length of content
    mov     x16, #4             // syscall 4 = write
    svc     #0x80

    // Close the file
    // close(fd)
    mov     x0, x19             // fd
    mov     x16, #6             // syscall 6 = close
    svc     #0x80

    adrp    x0, msg_written@PAGE
    add     x0, x0, msg_written@PAGEOFF
    mov     x1, #5
    bl      print_string
    bl      print_newline

    // ==========================================
    // PART 2: Read the file back and display it
    // ==========================================

    adrp    x0, msg_reading@PAGE
    add     x0, x0, msg_reading@PAGEOFF
    mov     x1, #20
    bl      print_string
    bl      print_newline

    // open("sample.txt", O_RDONLY)
    //   O_RDONLY = 0x0000
    adrp    x0, filename@PAGE
    add     x0, x0, filename@PAGEOFF
    mov     x1, #0              // O_RDONLY
    mov     x2, #0              // mode (unused for read)
    mov     x16, #5             // syscall 5 = open
    svc     #0x80

    cmp     x0, #0
    b.lt    open_error

    mov     x19, x0             // x19 = file descriptor

    // Read the file contents
    // read(fd, buffer, max_size)
    mov     x0, x19             // fd
    adrp    x1, read_buf@PAGE
    add     x1, x1, read_buf@PAGEOFF
    mov     x2, #512            // read up to 512 bytes
    mov     x16, #3             // syscall 3 = read
    svc     #0x80

    mov     x20, x0             // x20 = bytes read

    // Close the file
    mov     x0, x19
    mov     x16, #6
    svc     #0x80

    // Print what we read
    adrp    x0, msg_contents@PAGE
    add     x0, x0, msg_contents@PAGEOFF
    mov     x1, #21
    bl      print_string
    bl      print_newline

    adrp    x0, read_buf@PAGE
    add     x0, x0, read_buf@PAGEOFF
    mov     x1, x20             // length = bytes read
    bl      print_string

    // Print the byte count
    adrp    x0, msg_bytes@PAGE
    add     x0, x0, msg_bytes@PAGEOFF
    mov     x1, #6
    bl      print_string

    mov     x0, x20
    bl      print_uint

    adrp    x0, msg_bytes2@PAGE
    add     x0, x0, msg_bytes2@PAGEOFF
    mov     x1, #7
    bl      print_string

    // Success exit
    mov     x0, #0
    mov     x16, #1
    svc     #0x80

open_error:
    // x0 contains the negative error code
    adrp    x0, msg_error@PAGE
    add     x0, x0, msg_error@PAGEOFF
    mov     x1, #27
    bl      print_string

    mov     x0, #1              // exit code 1
    mov     x16, #1
    svc     #0x80

// ---- Data ----
.data
filename:       .asciz  "sample.txt"        // .asciz adds null terminator
file_content:   .ascii  "Hello from ARM64 assembly!\nFile I/O works!\n"
msg_creating:   .ascii  "Creating file...  "
msg_written:    .ascii  "Done!"
msg_reading:    .ascii  "Reading file back..."
msg_contents:   .ascii  "--- File contents ---"
msg_bytes:      .ascii  "(Read "
msg_bytes2:     .ascii  " bytes)\n"
msg_error:      .ascii  "Error: could not open file\n"
newline:        .ascii  "\n"
num_buf:        .space  20
read_buf:       .space  512
