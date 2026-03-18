# Lesson 10 — String to Number

## Goal

Convert a decimal string (like `"25"`) into a binary integer we can do math
with. This is the inverse of lesson 08's `print_uint` and the last piece we
need to build an interactive calculator.

## Build & run

```bash
make run
# Enter a number: 25
# You entered: 25
# Doubled: 50
# Squared: 625
```

Or: `echo "25" | ./program`

## New concepts

### The parsing algorithm

To convert `"25"` to the number 25:

```
Start: result = 0

Read '2': result = 0 * 10 + 2 = 2
Read '5': result = 2 * 10 + 5 = 25

Done → 25
```

In general: `result = result * 10 + digit` for each character.

```asm
mul     x0, x0, x6      // result *= 10
add     x0, x0, x5      // result += digit
```

### Checking for digits

We need to stop parsing when we hit a non-digit character (like the newline
at the end of the input). The trick:

```asm
sub     w5, w5, #0x30   // Subtract '0' — converts ASCII to digit value
cmp     w5, #9           // Is it 0–9?
b.hi    .Lparse_done     // If higher (unsigned), it's not a digit
```

**`b.hi`** is a condition code we haven't used before. It means "branch if
**higher**" using **unsigned** comparison. The difference from `b.gt`:

- `b.gt` — greater than (signed): treats values as potentially negative
- `b.hi` — higher (unsigned): treats values as always positive

Using unsigned comparison here is clever: if the original character was less
than `'0'` (e.g., a newline, `0x0A`), subtracting `0x30` wraps around to a
very large unsigned number (like 4 billion), which is definitely `> 9`. So one
comparison catches both "below '0'" and "above '9'."

### Register + register addressing: `[x2, x4]`

```asm
ldrb    w5, [x2, x4]    // Load byte at address (x2 + x4)
```

This is a new form of the bracket syntax. In lesson 03, we saw `[x5]` — load
from the address in one register. Here, `[x2, x4]` means "add the values in
`x2` and `x4` together, and use the sum as the memory address."

This is **register + register** addressing. `x2` is the base (string start),
`x4` is the index. Together they point to the current character. This is like
`string[i]` in C.

### Callee-saved register discipline

In this lesson, `print_uint` properly saves and restores `x19`–`x22`:

```asm
print_uint:
    stp     x29, x30, [sp, #-48]!
    stp     x19, x20, [sp, #16]    // Save callee-saved regs we'll use
    stp     x21, x22, [sp, #32]

    // ... function body uses x19–x22 freely ...

    ldp     x21, x22, [sp, #32]    // Restore in reverse order
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret
```

This is essential: `_start` stores the parsed number in `x19`, then calls
`print_uint`. If `print_uint` didn't save/restore `x19`, the parsed number
would be lost. This is the calling convention from lesson 07 in practice.

### Stack frame layout

The stack frame for `print_uint` looks like:

```
sp+40  │ x22 (saved)    │
sp+32  │ x21 (saved)    │
sp+24  │ x20 (saved)    │
sp+16  │ x19 (saved)    │
sp+8   │ x30 / LR       │
sp+0   │ x29 / FP       │  ← x29 points here
```

We allocate 48 bytes (3 pairs of 16 bytes), keeping the 16-byte alignment.

## Exercises

1. Enter `0`. Does it parse correctly? What about an empty input (just
   press Enter)?
2. Enter `abc`. What number does `parse_uint` return? (Hint: it stops at
   the first non-digit and returns 0.)
3. Enter `123abc456`. What happens? Only `123` is parsed — the function
   stops at `'a'`.
4. Modify `parse_uint` to handle negative numbers: if the first character
   is `'-'`, skip it, parse the rest, then negate the result with
   `neg x0, x0`.
5. What's the largest number you can enter before overflow? (Hint: a 64-bit
   unsigned integer maxes out at 18,446,744,073,709,551,615.)

## What's next

We have all the building blocks: reading input, parsing numbers, doing math,
and printing results. In the next lesson, we combine them into a calculator
that adds two user-provided numbers.
