# ARM64 Assembly from Scratch — macOS (Apple Silicon)

A hands-on course for learning pure ARM64 (AArch64) assembly on macOS.
Each lesson lives on its own branch, building on the previous one.

## Prerequisites

- Mac with Apple Silicon (M1/M2/M3/M4)
- Xcode Command Line Tools (`xcode-select --install`)

## Lessons

| Branch | Topic |
|--------|-------|
| `lesson-01-exit` | Your first program — just exit |
| `lesson-02-hello-world` | Writing to stdout |
| `lesson-03-registers` | Registers and data types |
| `lesson-04-arithmetic` | Math operations |
| `lesson-05-branching` | Conditions and comparisons |
| `lesson-06-loops` | Iteration |
| `lesson-07-stack-and-functions` | The stack and subroutines |
| `lesson-08-printing-numbers` | Converting integers to text |
| `lesson-09-reading-input` | Reading from stdin |
| `lesson-10-string-to-number` | Parsing numeric input |
| `lesson-11-calculator` | Add two numbers from user input |
| `lesson-12-file-io` | Reading and writing files |

## How to use

```bash
# Switch to a lesson
git checkout lesson-01-exit

# Read the lesson
cat LESSON.md

# Build and run
make run

# Move to the next lesson
git checkout lesson-02-hello-world
```

Each branch has a `LESSON.md` that explains every new concept introduced.
Read the lesson, study the code, then experiment by modifying it.
