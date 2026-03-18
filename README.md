# ARM64 Assembly from Scratch — macOS (Apple Silicon)

A hands-on course for learning pure ARM64 (AArch64) assembly on macOS.
Each lesson lives in its own directory, building on the previous one.

## Prerequisites

- Mac with Apple Silicon (M1/M2/M3/M4)
- Xcode Command Line Tools (`xcode-select --install`)

## Lessons

| Directory | Topic |
|-----------|-------|
| `01-exit/` | Your first program — just exit |
| `02-hello-world/` | Writing to stdout |
| `03-registers/` | Registers and data types |
| `04-arithmetic/` | Math operations |
| `05-branching/` | Conditions and comparisons |
| `06-loops/` | Iteration |
| `07-stack-and-functions/` | The stack and subroutines |
| `08-printing-numbers/` | Converting integers to text |
| `09-reading-input/` | Reading from stdin |
| `10-string-to-number/` | Parsing numeric input |
| `11-calculator/` | Add two numbers from user input |
| `12-file-io/` | Reading and writing files |

## How to use

```bash
# Go to a lesson directory
cd 01-exit

# Read the lesson
cat LESSON.md

# Build and run
make run

# Move to the next lesson
cd ../02-hello-world
```

Each directory has a `LESSON.md` that explains every new concept introduced.
Read the lesson, study the code, then experiment by modifying it.
