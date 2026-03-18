# Lesson 04 — Arithmetic

## Goal

Perform addition, subtraction, multiplication, and division, and display the
results. We also learn how to **store** values to memory and convert numbers to
printable ASCII characters.

## Build & run

```bash
make run
# Output:
# 3 + 4 = 7
# 9 - 5 = 4
# 3 * 2 = 6
# 8 / 2 = 4
```

## New concepts

### Arithmetic instructions: three operands

Until now, `mov` took two operands (destination and source). Arithmetic
instructions take **three**: a destination and two sources.

```asm
add     x2, x0, x1     // x2 = x0 + x1
```

Read it as: "add `x0` and `x1`, put the result in `x2`." The destination is
still first, followed by two sources separated by commas.

This is different from many other architectures (and from math notation). In
ARM64, the result can go into a *different* register than either input — you
don't overwrite your operands unless you choose to.

| Instruction | Operation | Meaning |
|-------------|-----------|---------|
| `add x2, x0, x1` | x2 = x0 + x1 | Addition |
| `sub x2, x0, x1` | x2 = x0 - x1 | Subtraction |
| `mul x2, x0, x1` | x2 = x0 * x1 | Multiplication |
| `udiv x2, x0, x1` | x2 = x0 / x1 | Unsigned integer division |

You can also use an immediate (`#` value) as the last operand for `add` and
`sub`:

```asm
add     x2, x0, #10    // x2 = x0 + 10
sub     x2, x0, #1     // x2 = x0 - 1
```

But `mul` and `udiv` **require all register operands** — no immediates allowed.

### Signed vs unsigned division

- `udiv` — unsigned division (treats values as positive)
- `sdiv` — signed division (treats values as two's complement signed integers)

ARM64 has **no remainder instruction**. To get the remainder (modulo), use
the identity `remainder = dividend - (quotient * divisor)`:

```asm
udiv    x2, x0, x1     // x2 = x0 / x1
msub    x3, x2, x1, x0 // x3 = x0 - (x2 * x1) = x0 % x1
```

`msub` (multiply-subtract) computes `x3 = x0 - (x2 * x1)` in one instruction.

### Four-operand instructions: `msub` and `madd`

`msub` is our first **four-operand** instruction:

```asm
msub    x3, x2, x1, x0     // x3 = x0 - (x2 * x1)
```

Read it as: "multiply `x2` and `x1`, subtract that product from `x0`, put the
result in `x3`." The destination is still the first operand.

ARM64 has fused multiply-add/subtract instructions:

| Instruction | Operation |
|-------------|-----------|
| `madd x0, x1, x2, x3` | x0 = x3 + (x1 * x2) |
| `msub x0, x1, x2, x3` | x0 = x3 - (x1 * x2) |

These combine two operations in a single instruction, which is both faster
and saves you from needing a temporary register.

### Storing to memory: `strb`

In lesson 03, we **loaded** data from memory into registers using `ldr`.
Now we go the other direction — **storing** data from a register into memory
using `str`:

```asm
strb    w2, [x3]        // Store the lowest byte of w2 into address [x3]
```

The syntax mirrors `ldr`: the register comes first, then `[address]` in
brackets. The difference is the direction — `ldr` reads from `[x3]` into
`w2`, while `str` writes from `w2` into `[x3]`.

| Instruction | Stores | Suffix |
|-------------|--------|--------|
| `strb w2, [x3]` | 1 byte | **b** = byte |
| `strh w2, [x3]` | 2 bytes | **h** = halfword |
| `str  w2, [x3]` | 4 bytes | w register = 4 bytes |
| `str  x2, [x3]` | 8 bytes | x register = 8 bytes |

### Converting a digit to ASCII

Computers store numbers as binary. To **print** a number, we need its ASCII
character code. The ASCII digits are conveniently sequential:

```
'0' = 0x30 (48)
'1' = 0x31 (49)
...
'9' = 0x39 (57)
```

So for a single digit `d` (0–9): `ASCII character = d + 0x30`.

```asm
add     x2, x2, #0x30      // Convert digit to ASCII
```

This trick only works for single digits (0–9). In lesson 08, we'll build a
proper integer-to-string converter for multi-digit numbers.

### Layout trick: output buffer with placeholders

We lay out the entire output string in `.data` with placeholder `"0"` bytes,
then label those positions so we can overwrite them at runtime:

```asm
output:
    .ascii  "3 + 4 = "
add_result:
    .ascii  "0"             // <- overwritten at runtime with '7'
    .ascii  "\n"
```

This is a common pattern in assembly: pre-format your output buffer and patch
in the dynamic parts.

## Exercises

1. Add a computation for `7 % 3` (remainder) using `udiv` and `msub`. Print
   the result on a new line.
2. Compute `15 + 27`. This gives `42`, which is two digits. Can you store
   both digits? (Hint: divide by 10 to get the tens digit, use `msub` for
   the ones digit.)
3. What happens if you divide by zero with `udiv`? (On ARM64, it returns 0
   rather than crashing — unlike x86!)
4. Replace `udiv` with `sdiv`. Load `-8` into a register using `mov x0, #-8`
   and divide by 2. Is the result correct?

## What's next

So far, our programs execute every instruction in order. In the next lesson,
we'll learn to make decisions — comparing values and taking different paths
through the code.
