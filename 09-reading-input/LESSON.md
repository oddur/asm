# Lesson 09 — Reading Input

## Goal

Read text from the keyboard (stdin) and echo it back, using the `read` syscall.

## Build & run

```bash
make run
# Type something: hello
# You said: hello
```

Or with piped input:
```bash
echo "hello assembly" | ./program
```

## New concepts

### The `read` syscall

| Syscall | Number | Arguments |
|---------|--------|-----------|
| `read`  | 3      | `x0` = fd, `x1` = buffer, `x2` = max bytes |
| **Returns** | | `x0` = bytes actually read (or negative on error) |

```asm
mov     x0, #0          // fd 0 = stdin
mov     x1, buffer      // where to store the data
mov     x2, #128        // read at most 128 bytes
mov     x16, #3         // syscall 3 = read
svc     #0x80
// x0 now = number of bytes read
```

When reading from the terminal, `read` blocks until the user presses Enter.
The newline character (`\n`) is **included** in the data.

### Syscall return values

Every syscall returns a value in `x0`:
- For `read`: the number of bytes read, 0 for EOF, or a negative number for
  an error
- For `write`: the number of bytes written (or negative on error)
- For `exit`: never returns

Always check the return value. In our code:

```asm
cmp     x19, #0
b.le    exit        // If 0 (EOF) or negative (error), just exit
```

### Input buffers and `.space`

```asm
input_buf:  .space  128     // Reserve 128 zero bytes
```

The `read` syscall writes directly into this memory. We must ensure:
1. The buffer is large enough for the expected input
2. We pass the buffer size to `read` so it doesn't overflow

This is the assembly equivalent of:
```c
char input_buf[128];
int n = read(0, input_buf, 128);
```

### Buffer overflow — your first security lesson

If the user types more than 128 characters, `read` will only store 128 bytes
(because we passed that as the limit). Without this limit, a `read` with no
bounds check could overwrite memory beyond the buffer — this is a **buffer
overflow**, one of the oldest and most common security vulnerabilities.

In assembly, there is **no safety net**. The language doesn't check bounds.
**You** are responsible for every byte.

### File descriptor 0 — stdin

Just as fd 1 is stdout and fd 2 is stderr, fd 0 is **stdin**. When your
program runs interactively, stdin is connected to the keyboard. When you pipe
data (`echo "hi" | ./program`), stdin reads from the pipe.

### The data includes the newline

When the user types `hello` and presses Enter, `read` returns 6 bytes:
`h`, `e`, `l`, `l`, `o`, `\n`. The newline is part of the data. That's why
our echo output ends with a newline without us adding one explicitly.

## Exercises

1. After echoing, print the number of bytes read. (Use `print_uint` from
   lesson 08 — you'll need to copy it into this file.)
2. Read input twice — ask for a name, then ask for a favorite color, and
   print both.
3. Read until EOF by putting the `read` call in a loop. Keep reading and
   echoing until `read` returns 0.
4. What happens if you set the max read size to `#1`? The program reads one
   byte at a time — you'd need a loop to get a full line.

## What's next

We can read text, but to do math with user input, we need to convert strings
like `"42"` into the number 42. That's the topic of the next lesson.
