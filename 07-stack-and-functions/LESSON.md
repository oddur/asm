# Lesson 07 — The Stack and Functions

## Goal

Write reusable **subroutines** (functions) and understand the stack, calling
convention, and register preservation rules.

## Build & run

```bash
make run
# Output:
# Hello from a function!
# Called the same function twice!
# x19 is preserved!
```

## New concepts

### `bl` and `ret` — calling and returning

Two new instructions for calling functions:

```asm
bl      print_string    // Branch with Link: jump to print_string
```

**`bl`** stands for **Branch with Link**. It does two things:
1. Saves the address of the *next* instruction (the return address) into
   register `x30` (also called **LR**, the Link Register)
2. Jumps to the label `print_string`

This is how you "call" a function in assembly. The operand is a label name,
just like `b` from lesson 05.

Inside the function, when it's done:

```asm
ret                     // Jump to the address in x30 (return to caller)
```

**`ret`** jumps to whatever address is in `x30`. Since `bl` stored the return
address there, `ret` takes us back to right after the `bl` instruction. This
is like `return` in C.

Note: `ret` takes **no operands** — it always reads from `x30`.

### The problem: nested calls

What if `print_newline` calls `print_string`? The second `bl` overwrites
`x30` — now `print_newline` doesn't know where to return to! This is why we
need **the stack**.

### The stack and `sp`

The **stack** is a region of memory that grows **downward** (toward lower
addresses). The **stack pointer** register, written **`sp`**, always points
to the top of the stack. `sp` is a special register — it's not one of the
x0–x30 general-purpose registers.

```
High address    ┌──────────────┐
                │  older data  │
                ├──────────────┤
    sp ──────>  │  top of      │
                │  stack       │
                ├──────────────┤
                │  (free)      │
Low address     └──────────────┘
```

To **push** data onto the stack: subtract from `sp` (make room), then store.
To **pop** data off the stack: load, then add to `sp` (reclaim space).

### `stp` and `ldp` — store/load pair

ARM64's preferred way to push and pop uses **pair** instructions that save
or restore two registers at once:

```asm
stp     x29, x30, [sp, #-16]!
```

This is the most complex syntax we've seen yet. Let's break it down:

- **`stp`** — **Store Pair**. Stores two registers to memory.
- **`x29, x30`** — the two registers to store (frame pointer and link register)
- **`[sp, #-16]`** — the memory address. This means "`sp` minus 16 bytes."
  The `[brackets]` mean memory access (like lesson 03), and `#-16` is an
  offset added to `sp`.
- **`!`** — the **exclamation mark** is critical. It means **"write-back"** or
  **"pre-index"**: update `sp` to `sp - 16` **before** storing. Without the
  `!`, `sp` wouldn't change and we'd just be writing to a random spot below
  the stack.

So `stp x29, x30, [sp, #-16]!` means: "decrement sp by 16, then store x29
and x30 at that address." This is a **push**.

The reverse:

```asm
ldp     x29, x30, [sp], #16
```

- **`ldp`** — **Load Pair**. Loads two values from memory into registers.
- **`[sp], #16`** — note the `#16` is **outside** the brackets. This is
  **post-index**: load from `[sp]` first, **then** add 16 to `sp`. This is
  a **pop**.

Summary of the `!` and post-index syntax:

| Syntax | Name | Meaning |
|--------|------|---------|
| `[sp, #-16]!` | Pre-index (write-back) | sp = sp - 16, then access [sp] |
| `[sp], #16` | Post-index | Access [sp], then sp = sp + 16 |
| `[sp, #16]` | Offset (no `!`) | Access [sp + 16], sp unchanged |

`stp` stores two 64-bit registers (= 16 bytes) in one instruction.
`ldp` loads them back. **On Apple platforms, `sp` must always be 16-byte
aligned**, so always push/pop in multiples of 16 bytes.

### The stack frame

Every function begins and ends with this pattern:

```asm
my_function:
    stp     x29, x30, [sp, #-16]!   // PUSH: save frame pointer + return address
    mov     x29, sp                  // Set frame pointer to current sp

    // ... function body ...

    ldp     x29, x30, [sp], #16     // POP: restore and reclaim stack space
    ret                              // Return to caller
```

`x29` is the **frame pointer** (FP). Setting `FP = SP` creates a chain of
frame pointers that debuggers use to produce stack traces. This is required on
macOS.

### The AAPCS64 calling convention

The ARM64 calling convention specifies which registers are used for what:

| Registers | Role | Who preserves? |
|-----------|------|-----------------|
| `x0`–`x7` | Arguments & return value | **Caller** (expect them to be clobbered) |
| `x8` | Indirect result location | Caller |
| `x9`–`x15` | Temporaries | Caller (may be clobbered) |
| `x16`–`x17` | Intra-procedure scratch | Caller |
| `x18` | Platform reserved | **Don't touch** on macOS |
| `x19`–`x28` | Callee-saved | **Callee** (must save & restore) |
| `x29` (FP) | Frame pointer | Callee |
| `x30` (LR) | Link register | Callee |

**Key takeaway:**
- As a **caller**: put arguments in `x0`–`x7`. After the call, only `x19`–`x28`
  are guaranteed to still have your values.
- As a **callee**: you can freely use `x0`–`x15`. If you need `x19`–`x28`, you
  must save them on the stack first and restore them before returning.

### Function anatomy

```asm
// my_func(x0=arg1, x1=arg2) -> x0=result
my_func:
    stp     x29, x30, [sp, #-32]!   // Save FP, LR (and room for locals)
    mov     x29, sp
    stp     x19, x20, [sp, #16]     // Save callee-saved regs we'll use

    mov     x19, x0                 // Preserve arg1 across calls
    // ... do work ...
    mov     x0, x19                 // Return value in x0

    ldp     x19, x20, [sp, #16]     // Restore callee-saved regs
    ldp     x29, x30, [sp], #32     // Restore FP, LR
    ret
```

Note `[sp, #16]` — this is offset addressing **without** `!`. It accesses
memory at `sp + 16` without changing `sp`. We only move `sp` with the first
`stp` (which uses `!`) and the last `ldp` (which uses post-index).

## Exercises

1. Write a `print_char` function that takes a character value in `x0` and
   prints it. (Hint: store the byte on the stack and pass `sp` as the buffer.)
2. Write a function `print_twice` that takes a string pointer and length, and
   calls `print_string` twice. Make sure the string and length survive across
   the first call. (Use `x19` and `x20`.)
3. What happens if you remove the `stp`/`ldp` from `print_newline`? It calls
   `print_string` with `bl`, which clobbers `x30`. Try it — the program will
   crash or loop.
4. Write a function that calls itself recursively. Print a `*` each time and
   decrement a counter. Stop when the counter reaches 0.

## What's next

We can now write and call functions. But we can still only print single-digit
numbers. In the next lesson, we'll build a function to convert any integer
to its decimal string representation.
