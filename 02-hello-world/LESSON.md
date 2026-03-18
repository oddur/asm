# Lesson 02 — Hello World: Writing to stdout

## Goal

Make our program produce visible output by writing text to the terminal.

## Build & run

```bash
make run
# Output: Hello, ARM64!
```

## New concepts

### Sections: `.text` vs `.data`

A program is divided into **sections**:

| Section | Contains | Permissions |
|---------|----------|-------------|
| `.text` | Executable code (instructions) | Read + Execute |
| `.data` | Mutable data (variables) | Read + Write |

Our code goes in `.text` (the default — we don't need to declare it
explicitly). Our message string goes in `.data`.

```asm
.data
message:
    .ascii  "Hello, ARM64!\n"
```

### Labels

`message:` is a **label** — a name for a memory address. It doesn't generate
any machine code. It simply gives us a way to refer to the address where
`"Hello, ARM64!\n"` lives in memory.

Labels in the code section (like `_start:`) mark instruction addresses.
Labels in the data section (like `message:`) mark data addresses.

### The `.ascii` directive

```asm
.ascii  "Hello, ARM64!\n"
```

`.ascii` places raw bytes into the output. Each character becomes its ASCII
value. `\n` becomes byte `0x0A` (newline). Note: `.ascii` does **not** add a
null terminator. If you want one, use `.asciz` instead. (We don't need one here
because `write` uses an explicit length.)

### Loading an address: `adrp` + `add`

This is the most important new pattern in this lesson. To pass our string to
the `write` syscall, we need to put the **memory address** of `message` into
register `x1`. But a memory address is a 64-bit number, and an ARM64
instruction is only 4 bytes (32 bits) — there's no room to fit a full address
in a single instruction. So we build the address in two steps:

```asm
adrp    x1, message@PAGE        // Step 1: get the "page" address
add     x1, x1, message@PAGEOFF // Step 2: add the offset within the page
```

Let's break down the syntax:

- **`adrp`** — "Address of Page." This instruction loads the base address of
  the 4KB memory **page** that contains `message`. Think of a page as a 4096-byte
  block of memory. This gets us close, but not exact.
- **`message@PAGE`** — the `@PAGE` suffix is an instruction to the assembler:
  "calculate which page `message` lives on." It's not a register or a number —
  it's a compile-time computation.
- **`add x1, x1, message@PAGEOFF`** — this is the `add` instruction (which
  we'll formally learn in lesson 04). It adds a value to `x1` and stores the
  result back in `x1`. Notice `x1` appears **twice**: as both the destination
  and the first source. We're adding the offset to what `adrp` already put
  there.
- **`message@PAGEOFF`** — "the offset of `message` within its page." If
  `message` lives at address 4100, the page starts at 4096, so the page
  offset is 4.

After these two instructions, `x1` holds the exact address of `message`.

> Think of it like a street address: `adrp` gets you to the right block,
> `add @PAGEOFF` gets you to the right house number on that block.

You'll see this two-instruction pattern every time we load an address. It
becomes second nature quickly.

### The `write` syscall

| Syscall | Number | Arguments |
|---------|--------|-----------|
| `write` | 4      | `x0` = file descriptor, `x1` = buffer address, `x2` = byte count |

### File descriptors

Every running program starts with three open **file descriptors**:

| fd | Name | Purpose |
|----|------|---------|
| 0  | stdin  | Keyboard input |
| 1  | stdout | Terminal output |
| 2  | stderr | Error output |

We write to fd `1` (stdout) so the text appears in the terminal.

### Counting bytes

We pass `#14` as the byte count because `"Hello, ARM64!\n"` is exactly 14
bytes. Count carefully — getting this wrong will either truncate your output or
print garbage from adjacent memory.

```
H  e  l  l  o  ,     A  R  M  6  4  !  \n
1  2  3  4  5  6  7  8  9  10 11 12 13 14
```

### Full program walkthrough

```asm
_start:
    mov     x0, #1              // x0 = 1 (file descriptor for stdout)
    adrp    x1, message@PAGE    // x1 = page containing message
    add     x1, x1, message@PAGEOFF  // x1 = exact address of message
    mov     x2, #14             // x2 = 14 (number of bytes to write)
    mov     x16, #4             // x16 = 4 (syscall number for "write")
    svc     #0x80               // Call the kernel: write(1, message, 14)

    mov     x0, #0              // x0 = 0 (exit code)
    mov     x16, #1             // x16 = 1 (syscall number for "exit")
    svc     #0x80               // Call the kernel: exit(0)
```

Notice the program is just two syscalls back to back: first `write`, then
`exit`. Before each `svc`, we load the appropriate registers. The CPU executes
these instructions one after another, top to bottom.

## Exercises

1. Change the message to your own text. Remember to update the byte count in
   `x2` to match.
2. Add a second `write` call to print a second line.
3. What happens if you set `x2` to a number larger than the string length?
   Try it — you'll see whatever bytes happen to live in memory after your string.
4. Change `x0` from `#1` to `#2` — this writes to stderr instead of stdout.
   The output looks the same, but you can prove it:
   ```bash
   ./program 1>/dev/null    # suppresses stdout — stderr still shows
   ./program 2>/dev/null    # suppresses stderr — stdout still shows
   ```

## What's next

We've been using registers `x0`, `x1`, `x2`, and `x16` without much
explanation. In the next lesson, we'll take a closer look at ARM64's register
file and how to work with different data sizes.
