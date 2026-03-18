# Lesson 06 — Loops

## Goal

Repeat a block of code multiple times. We'll count down from 9 to 0 and print
each number — the assembly equivalent of a `for` or `while` loop.

## Build & run

```bash
make run
# Output:
# Countdown!
#
# 9
# 8
# 7
# 6
# 5
# 4
# 3
# 2
# 1
# 0
# Liftoff!
```

## New concepts

### Loop structure

Every loop has three parts:

```
1. Initialize        mov x19, #9          (set counter)
2. Body              ...                  (do work)
3. Update & check    subs x19, x19, #1   (decrement)
                     b.ge loop            (repeat if >= 0)
```

This maps to C like:

```c
for (int i = 9; i >= 0; i--) {
    // body
}
```

### `subs` — the `s` suffix means "set flags"

```asm
subs    x19, x19, #1    // x19 = x19 - 1, AND set condition flags
```

Look at the instruction name carefully: it's `subs`, not `sub`. That extra
**`s`** at the end is doing something important.

- **`sub x19, x19, #1`** — subtracts 1 from x19. That's it. The CPU does the
  math, stores the result, and moves on. It does **not** remember anything
  about the result (was it zero? negative? etc.).

- **`subs x19, x19, #1`** — does the **exact same subtraction**, but also
  tells the CPU to **update the condition flags** (the NZCV flags from
  lesson 05) based on the result. Those flags are what conditional branches
  like `b.ge` look at to decide whether to jump.

Think of it this way: without the `s`, the CPU has amnesia — it does the math
but immediately forgets whether the answer was positive, negative, or zero.
With the `s`, it writes down a note ("the result was negative", "the result
was zero", etc.) that the next branch instruction can read.

**This `s` suffix is not unique to `sub`.** You can add it to other
arithmetic instructions too:

| Instruction | What it does                              |
|-------------|-------------------------------------------|
| `add`       | adds, does NOT set flags                  |
| `adds`      | adds AND sets flags                       |
| `sub`       | subtracts, does NOT set flags             |
| `subs`      | subtracts AND sets flags                  |

Without `subs`, we'd need two separate instructions to accomplish the same
thing:

```asm
sub     x19, x19, #1    // decrement (no flags updated)
cmp     x19, #0         // compare against 0 (this sets the flags)
```

`subs` lets us combine the decrement and the flag-setting into one
instruction — fewer instructions means a tighter, faster loop.

### `b.ge` — branch if greater than or equal to zero

```asm
subs    x19, x19, #1    // x19 = x19 - 1, set flags
b.ge    loop             // if x19 >= 0, jump back to "loop"
```

The `.ge` part is a **condition suffix** on the branch instruction. It stands
for **"greater than or equal"** (to zero, when used after `subs`). You read
it as: "branch if the result was greater than or equal to zero."

Here's what happens step by step in our countdown:

1. `subs x19, x19, #1` subtracts 1 from x19 and sets the condition flags.
2. `b.ge loop` checks those flags. If x19 hasn't gone negative (i.e., the
   result was >= 0), it jumps back to `loop` for another iteration.
3. When x19 finally goes from 0 to -1, the result is negative, so `b.ge`
   does NOT branch — execution falls through to the next instruction and
   the loop ends.

This is why our countdown prints 0 and then stops: after printing 0, `subs`
makes x19 become -1 (negative), and `b.ge` sees that and stops looping.

Other condition suffixes you'll commonly see on branches:

| Suffix | Meaning                | Example   |
|--------|------------------------|-----------|
| `.eq`  | equal (zero)           | `b.eq`    |
| `.ne`  | not equal (not zero)   | `b.ne`    |
| `.gt`  | greater than           | `b.gt`    |
| `.ge`  | greater than or equal  | `b.ge`    |
| `.lt`  | less than              | `b.lt`    |
| `.le`  | less than or equal     | `b.le`    |

### Loop patterns

**Count down (most common in assembly):**
```asm
    mov     x19, #10
loop:
    // ... body ...
    subs    x19, x19, #1
    b.ne    loop            // repeat while x19 != 0
```

**Count up:**
```asm
    mov     x19, #0
loop:
    // ... body ...
    add     x19, x19, #1
    cmp     x19, #10
    b.lt    loop            // repeat while x19 < 10
```

**Do-while vs while:** Our loop always executes at least once (the check is at
the bottom). To check before the first iteration, add a `cmp` + conditional
branch before the loop body.

### `cbnz` / `cbz` — compare and branch in one instruction

There is an even shorter way to write a "loop until zero" countdown:

```asm
    mov     x19, #10
loop:
    // ... body ...
    sub     x19, x19, #1
    cbnz    x19, loop       // if x19 is NOT zero, jump to loop
```

**`cbnz`** stands for **"Compare and Branch if Not Zero."** It checks whether
the register is not zero and branches if so — all in a single instruction.
You don't need `subs` or `cmp` before it; `cbnz` does the zero-check
internally.

There's a matching instruction **`cbz`** — **"Compare and Branch if Zero"** —
which branches when the register IS zero:

```asm
cbz     x19, done        // if x19 IS zero, jump to "done"
```

When should you use each approach?

| Goal                         | Instructions needed                    |
|------------------------------|----------------------------------------|
| Loop until zero              | `sub` + `cbnz` (2 instructions)        |
| Loop until zero (also works) | `subs` + `b.ne` (2 instructions)       |
| Loop until negative          | `subs` + `b.ge` (2 instructions)       |

`cbnz`/`cbz` and `subs` + `b.ne` both take two instructions, but `cbnz` is
nice because it lets you use plain `sub` (no `s` suffix needed) — the intent
is clearer since you are explicitly saying "loop while not zero." Use
`subs` + `b.ge` when you need to loop through zero and stop only when the
counter goes negative (like our countdown from 9 through 0).

**Important:** `cbnz` and `cbz` do **not** modify the condition flags. They
just peek at the register value and decide whether to branch.

### Why `x19`?

We use `x19` for the counter instead of `x0`–`x7`. Why? Because `x0`–`x7`
get **clobbered** (overwritten) by the syscall — the kernel doesn't preserve
them. Registers `x19`–`x28` are **callee-saved** — they survive across function
calls and syscalls. We'll formalize this in the next lesson, but for now:

> **Rule of thumb:** Use `x19`–`x28` for values that must survive across
> syscalls or function calls.

### Patching a buffer in a loop

Each iteration, we convert the counter to ASCII and write it into the same
byte in memory:

```asm
add     x20, x19, #0x30    // digit -> ASCII
strb    w20, [x21]          // overwrite the '0' in the buffer
```

Then we print that buffer. Since we're reusing the same buffer, we don't need
separate strings for each number.

## Exercises

1. Change the loop to count **up** from 0 to 9 instead of down.
2. Print only even numbers (hint: use `tst x19, #1` — it sets the Z flag if
   bit 0 is zero, meaning the number is even).
3. Make a nested loop that prints a 5x5 grid of `*` characters.
4. Implement a loop that computes the sum 1+2+3+...+10 and stores the result.
   (You can't print it yet since it's two digits — we'll handle that in
   lesson 08.)

## What's next

We've been using registers `x19`–`x21` with a vague warning about "callee-saved."
In the next lesson, we'll properly learn the stack and function calling
convention — how to write reusable subroutines and manage register preservation.
