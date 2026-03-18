# Lesson 03 — Registers and Data Types

## Goal

Understand the ARM64 register file and how to work with values of different
sizes — bytes, halfwords, words, and doublewords.

## Build & run

```bash
make run
# Output: Registers loaded OK.
```

The interesting part of this lesson is in the code itself. Study `program.s`
and trace through what each instruction does.

## New concepts

### The ARM64 register file

ARM64 gives you **31 general-purpose registers**, each 64 bits wide:

```
x0  x1  x2  x3  x4  x5  x6  x7     (arguments / return values)
x8  x9  x10 x11 x12 x13 x14 x15    (temporaries)
x16 x17                              (intra-procedure-call scratch)
x18                                  (platform reserved — don't use on macOS)
x19 x20 x21 x22 x23 x24 x25 x26 x27 x28 (callee-saved)
x29 = FP (frame pointer)
x30 = LR (link register — return address)
```

Plus two special registers:
- **SP** — the stack pointer
- **XZR / WZR** — the zero register (always reads as 0, writes are discarded)

### 64-bit vs 32-bit: `x` vs `w`

Every register has two names that refer to different widths of the **same**
physical register:

| Name | Width | Bits | Example |
|------|-------|------|---------|
| `x0` | 64-bit (full register) | all 64 bits | `mov x0, #1000` |
| `w0` | 32-bit (lower half of x0) | bits 0–31 only | `mov w0, #255` |

Think of it like this: `x0` is a 64-bit "box." `w0` is a window into the
bottom half of that same box. There is no separate `w0` register — it's just
a way to access the lower 32 bits of `x0`.

**Why does this exist?** Some operations only need 32 bits. Using `w` registers
generates smaller, faster instructions and makes intent clear.

**Important:** Writing to `w0` **zeroes the upper 32 bits** of `x0`. This is
not just a window — it's a destructive operation on the upper half.

```
Before: x0 = 0xFFFFFFFF_00000000
After "mov w0, #1":  x0 = 0x00000000_00000001
                                    ^^^^^^^^ written
                      ^^^^^^^^ zeroed!
```

### Moving register to register

In lesson 01, we used `mov` with an immediate (`#` value). You can also copy
one register into another:

```asm
mov     x3, x0              // x3 = copy of x0
```

No `#` sign — `x0` is a register, not a literal number. After this, `x3` and
`x0` both hold the same value. Changing one later won't affect the other —
it's a copy, not a reference.

### Loading large constants: `movz` and `movk`

`mov` with an immediate (`#`) can only encode values up to 16 bits (0–65535).
For larger values, you build them in 16-bit chunks using two specialized
instructions:

```asm
movz    x4, #0xBEEF              // x4 = 0x0000_0000_0000_BEEF
movk    x4, #0xDEAD, lsl #16    // x4 = 0x0000_0000_DEAD_BEEF
```

- **`movz`** (move with zero) — **clears** the entire register to zero, then
  places the 16-bit value at the specified position. Always use this first.
- **`movk`** (move with keep) — inserts 16 bits into the register **without**
  clearing the rest. Use this for subsequent chunks.
- **`, lsl #16`** — this extra operand means "logical shift left by 16 bits."
  It positions the value into bits 16–31 instead of bits 0–15. Think of it as
  choosing which "slot" of the 64-bit register to fill.

A 64-bit register has four 16-bit slots:

```
|  bits 63–48  |  bits 47–32  |  bits 31–16  |  bits 15–0   |
   lsl #48        lsl #32        lsl #16        lsl #0 (default)
```

So to load a 32-bit value like `0xDEADBEEF`, you need two instructions.
For a 64-bit value, you'd need up to four.

### Data types in the data section

```asm
my_byte:    .byte   0x41                // 1 byte
my_half:    .short  1024                // 2 bytes (halfword)
my_word:    .long   12345               // 4 bytes (word)
my_quad:    .quad   0x123456789ABCDEF0  // 8 bytes (doubleword)
```

| Directive | Size | ARM name |
|-----------|------|----------|
| `.byte`   | 1 byte  | Byte |
| `.short` / `.hword` | 2 bytes | Halfword |
| `.long` / `.word` | 4 bytes | Word |
| `.quad` | 8 bytes | Doubleword |

### Loading from memory: `ldr` and the bracket syntax `[x5]`

So far, all our values have been immediates (`#42`) or other registers. But
data can also live in **memory** (RAM) — that's what the `.data` section is
for. To get data from memory into a register, we use **load** instructions.

```asm
ldr     w7, [x5]        // Load 4 bytes from the address in x5 into w7
```

The **square brackets `[x5]`** are critical syntax. They mean: "use the value
in `x5` as a **memory address**, go to that location in memory, and read the
data stored there." This is called **indirect addressing** — `x5` doesn't
contain the data, it contains the *address* where the data lives.

It's like the difference between "the number 42" (`#42`) and "whatever's
written on the paper in locker 42" (`[x5]` where x5 = 42).

Different load instructions read different amounts of data:

| Instruction | Reads | Suffix meaning |
|-------------|-------|----------------|
| `ldrb w6, [x5]` | 1 byte | **b** = byte |
| `ldrh w6, [x5]` | 2 bytes | **h** = halfword |
| `ldr  w6, [x5]` | 4 bytes | (no suffix) w register = 4 bytes |
| `ldr  x6, [x5]` | 8 bytes | (no suffix) x register = 8 bytes |

Notice: for `ldr` without a suffix, the register name tells the CPU how many
bytes to load — `w` means 4 bytes, `x` means 8 bytes.

### Alignment matters

After placing odd-sized data (like a single `.byte`), memory may be
misaligned. The `.align 4` directive pads to a 16-byte boundary. ARM64
requires aligned access for most load/store operations.

## Exercises

1. Add a `.quad` with the value `0xFFFFFFFFFFFFFFFF`, load it into `x9`, then
   load it with `ldr w10, [x5]`. What value ends up in `w10`? Why?
2. Use `movz` and `movk` to construct the value `0xCAFEBABE12345678` in `x4`.
   How many instructions do you need?
3. What is register `x18` used for on macOS? (Hint: Apple reserves it — using
   it will crash your program.)
4. Create a `.byte` with the value `0x48` (`'H'`), load it, and think about
   how you could print a single character.

## What's next

Now that we understand registers and data, we'll use them to perform arithmetic
— addition, subtraction, multiplication, and division.
