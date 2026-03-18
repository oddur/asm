// program.s — Lesson 01: Exit
//
// The simplest possible ARM64 program on macOS.
// It does nothing except tell the operating system: "I'm done."

.global _start          // Expose _start so the linker can find our entry point
.align 4                // Align code to 16-byte boundary (required on ARM64)

_start:
    // exit(0)
    mov     x0, #0      // x0 = exit code (0 means success)
    mov     x16, #1     // x16 = syscall number (1 = exit)
    svc     #0x80       // Ask the kernel to execute the syscall
