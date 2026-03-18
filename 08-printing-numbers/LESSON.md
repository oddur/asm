# Lesson 08 — Printing Numbers

## Goal

Build a reusable `print_uint` function that converts any unsigned 64-bit
integer to its decimal string representation and prints it. This unlocks
the ability to display computation results.

## Build & run

```bash
make run
# Output:
# 42 = 42
# 12345 = 12345
# 0 = 0
# 1000000 = 1000000
# 123 + 456 = 579
```

## New concepts

### The integer-to-string algorithm

To print the number `12345`, we need the characters `'1' '2' '3' '4' '5'`.
The classic algorithm:

1. **Divide** the number by 10
2. The **remainder** is the last digit — convert it to ASCII (`+ 0x30`)
3. **Push** it onto the stack (we extract digits in reverse order)
4. The **quotient** becomes the new number
5. Repeat until the number is 0
6. **Pop** all digits off the stack (now in the correct order) and print

```
12345 / 10 = 1234  remainder 5  → push '5'
 1234 / 10 = 123   remainder 4  → push '4'
  123 / 10 = 12    remainder 3  → push '3'
   12 / 10 = 1     remainder 2  → push '2'
    1 / 10 = 0     remainder 1  → push '1'

Pop: '1' '2' '3' '4' '5'  → "12345"
```

### Using the stack as temporary storage

We push each digit onto the stack as we extract it:

```asm
sub     sp, sp, #16         // Allocate 16 bytes (alignment!)
strb    w3, [sp]            // Store the ASCII digit
```

Then pop them in reverse order:

```asm
ldrb    w23, [sp]           // Read the digit
add     sp, sp, #16         // Free the stack slot
```

This is a natural use of the stack's LIFO (Last In, First Out) property —
the digits come out in the opposite order from how they went in, which is
exactly what we need.

### Remainder with `msub`

ARM64 has no modulo instruction. We compute `remainder = n - (quotient * 10)`:

```asm
udiv    x2, x19, x1        // quotient  = n / 10
msub    x3, x2, x1, x19   // remainder = n - (quotient * 10)
```

### Local labels: `.L` prefix

```asm
.Lextract_digits:
.Lwrite_digits:
.Lcopy_loop:
```

These look like regular labels, but the `.L` prefix makes them **local** —
they're visible only within the current file. The assembler and linker won't
export them as symbols. Use them for branch targets inside a function (like
loop tops and if/else blocks) to avoid name collisions.

By convention: `_start` and `print_string` are "public" labels (functions you
might call from elsewhere). `.Lpu_extract` is a private implementation detail.

### `.space` — reserving an empty buffer

```asm
num_buf:    .space  20      // Reserve 20 zero bytes
```

`.space N` is a directive that reserves N bytes of zeroed memory. Unlike
`.ascii` (which stores specific characters), `.space` just allocates room
that your code can write into later. We use a 20-byte buffer because a
64-bit unsigned integer can have at most 20 decimal digits
(max value: 18,446,744,073,709,551,615).

### Restoring `sp` with the frame pointer

At the end of `print_uint`, we do:

```asm
mov     sp, x29             // Restore sp from saved frame pointer
ldp     x29, x30, [sp], #16
ret
```

This is a safety net — even if our stack pushes left `sp` in an unexpected
state, the frame pointer (`x29`) always points to where `sp` was at the start
of the function. This pattern is common in functions that do dynamic stack
allocation.

## Exercises

1. Modify `print_uint` to handle signed integers. (Hint: check if the number
   is negative, print a `'-'`, then negate it and print the absolute value.)
2. Write a `print_hex` function that converts a number to hexadecimal.
   (Hint: divide by 16 instead of 10, and map remainders 10–15 to 'A'–'F'.)
3. Print the result of `65535 * 65535`. Does it overflow a 32-bit integer?
   Use 64-bit multiplication to get the correct answer.
4. Write a `print_binary` function to display a number in binary.

## What's next

We can now print numbers, but we still can't get input from the user. In the
next lesson, we'll learn to read from stdin.
