# Lesson 12 — File I/O: Reading and Writing Files

## Goal

Learn to create, write, read, and close files using system calls. This is the
most "real-world" lesson — file I/O is how programs persist data and interact
with the filesystem.

## Build & run

```bash
make run
# Creating file...  Done!
# Reading file back...
# --- File contents ---
# Hello from ARM64 assembly!
# File I/O works!
# (Read 43 bytes)

ls -la sample.txt
# -rw-r--r--  1 user  staff  43  ... sample.txt

cat sample.txt
# Hello from ARM64 assembly!
# File I/O works!
```

## New concepts

### File I/O syscalls

| Syscall | Number | Arguments | Returns |
|---------|--------|-----------|---------|
| `open`  | 5 | `x0`=path, `x1`=flags, `x2`=mode | fd (or negative error) |
| `read`  | 3 | `x0`=fd, `x1`=buffer, `x2`=count | bytes read |
| `write` | 4 | `x0`=fd, `x1`=buffer, `x2`=count | bytes written |
| `close` | 6 | `x0`=fd | 0 on success |

### Opening a file: `open`

```asm
// open("sample.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644)
adrp    x0, filename@PAGE
add     x0, x0, filename@PAGEOFF    // path (null-terminated!)
mov     x1, #0x0601                  // flags
mov     x2, #0x1A4                   // mode = 0644
mov     x16, #5                      // syscall = open
svc     #0x80
// x0 = new file descriptor (or negative error code)
```

**Important:** The filename must be **null-terminated** (end with a `0x00`
byte). That's why we use `.asciz` instead of `.ascii`:

```asm
filename:   .asciz  "sample.txt"     // .asciz = .ascii + null byte
```

### File open flags

Flags control how the file is opened. They're combined with bitwise OR:

| Flag | Value | Meaning |
|------|-------|---------|
| `O_RDONLY` | `0x0000` | Read only |
| `O_WRONLY` | `0x0001` | Write only |
| `O_RDWR`   | `0x0002` | Read and write |
| `O_CREAT`  | `0x0200` | Create if doesn't exist |
| `O_TRUNC`  | `0x0400` | Truncate (empty) if exists |
| `O_APPEND` | `0x0008` | Append to end |

To write a new file: `O_WRONLY | O_CREAT | O_TRUNC = 0x0601`

### File permissions: the mode

When creating a file, `x2` specifies the Unix permissions:

```
0644 octal = 0x1A4 hex = 110 100 100 binary
                          rw- r-- r--
                          ^   ^   ^
                          |   |   └── others: read only
                          |   └────── group:  read only
                          └────────── owner:  read + write
```

### File descriptors revisited

`open` returns a new **file descriptor** — a small integer the kernel uses to
track the open file. It's typically 3 or higher (since 0, 1, 2 are stdin,
stdout, stderr).

We save this fd and use it in subsequent `read`, `write`, and `close` calls.

### Error checking

```asm
cmp     x0, #0
b.lt    open_error      // Negative return = error
```

On macOS, syscall errors return a negative value. Common error codes:
- `-2` (ENOENT): file not found
- `-13` (EACCES): permission denied
- `-24` (EMFILE): too many open files

### Closing a file: `close`

```asm
mov     x0, x19         // fd
mov     x16, #6         // syscall = close
svc     #0x80
```

Always close files when you're done. The kernel tracks open fds, and there's
a per-process limit (typically 256). Forgetting to close files is a resource
leak.

### The complete file I/O lifecycle

```
1. open()  → get a file descriptor
2. read() or write()  → transfer data
3. close() → release the file descriptor
```

This is the same pattern used by every programming language under the hood.
Python's `open()`, C's `fopen()`, Rust's `File::open()` — they all end up
making these same syscalls.

### `.asciz` — null-terminated strings

```asm
filename:   .asciz  "sample.txt"
```

`.asciz` is identical to `.ascii` but adds a `0x00` byte at the end. The
`open` syscall (and most C-compatible APIs) expect null-terminated strings.

Our `print_string` function uses an explicit length, so it doesn't need null
termination. But file paths passed to the kernel must be null-terminated.

## Summary of all syscalls used in this course

| Syscall | Number | Purpose |
|---------|--------|---------|
| `exit`  | 1 | Terminate the process |
| `read`  | 3 | Read bytes from a file descriptor |
| `write` | 4 | Write bytes to a file descriptor |
| `open`  | 5 | Open or create a file |
| `close` | 6 | Close a file descriptor |

These five syscalls are enough to build a surprising amount of functionality.
Real programs use dozens more (`mmap`, `fork`, `execve`, `socket`, ...) but
these are the foundation.

## Exercises

1. Modify the program to accept a filename as a command-line argument instead
   of hardcoding `"sample.txt"`. (Hint: at `_start`, the stack contains
   `argc` at `[sp]`, and `argv[0]` at `[sp, #8]`, `argv[1]` at `[sp, #16]`.)
2. Write a program that copies one file to another: read from an input file,
   write to an output file.
3. Read a file in a loop (in case it's larger than 512 bytes). Keep calling
   `read` until it returns 0.
4. Use the `lseek` syscall (number 199) to move to a specific position in a
   file before reading.

## Where to go from here

Congratulations — you've gone from zero to writing complete ARM64 assembly
programs that can:
- Do arithmetic
- Make decisions and loop
- Call functions with proper stack discipline
- Convert between numbers and strings
- Read user input
- Perform file I/O

Some next topics to explore:
- **Command-line arguments** — `argc` and `argv` are on the stack at `_start`
- **Memory allocation** — the `mmap` syscall for dynamic memory
- **Processes** — `fork` and `execve` to launch other programs
- **Networking** — `socket`, `bind`, `listen`, `accept` for a TCP server
- **SIMD/NEON** — ARM's vector instructions for parallel computation
- **Linking with C** — call `printf`, `malloc`, etc. from assembly
