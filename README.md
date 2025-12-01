# AoC25Mojo
 Advent of Code 2025 in Mojo 26.1 (Nightly)
# Advent of Code 2025 - Mojo

A clean, organized framework for solving Advent of Code 2025 in Mojo with support for test and full inputs.

## Environment

Use pixi! Install pixi, and enter the shell with "pixi shell" from inside the directory. 
To install:
```bash
curl -fsSL https://pixi.sh/install.sh | bash
```

[Here's more information on pixi.](https://docs.modular.com/pixi/)

## Project Structure

```
AoC25Mojo/
├── main.mojo           # Entry point and dispatcher
├── solution.mojo       # Solution interface/trait, Result type, defines
├── src/
│   ├── day01.mojo
│   ├── day02.mojo
│   └── ... (day03 through day12)
└── inputs/
    ├── test01.txt
    ├── full01.txt
    ├── test02.txt
    ├── full02.txt
    └── ... (test and full inputs for each day)
```

## Setup

### 1. Download Inputs

Before running solutions, download the input files from [adventofcode.com](https://adventofcode.com/2025).

For each day, save two files in the `inputs/` directory:
- `test{NN}.txt` - The example input from the problem description
- `full{NN}.txt` - Your actual puzzle input

### 2. Implement Solutions

Each day is a separate file in `solutions/`. Open `day01.mojo` and implement:

```mojo
@fieldwise_init
struct Solution01(Solution):
    
    fn partOne(self, input_file: String) -> String:
        # Read from input_file, solve part 1
        return "answer"

    fn partTwo(self, input_file: String) -> String:
        # Solve part 2
        return "answer"
```

Both methods receive the full path to the input file and should return the answer as a `String`.

## Usage

### Basic Usage

Run all days with full input:
```bash
mojo main.mojo
```

Run day 1 with test input:
```bash
mojo main.mojo 1 TEST
```

Run days 1, 3, and 5 with full input:
```bash
mojo main.mojo 1,3,5 FULL
```

Run all days with full and test inputs:
```bash
mojo main.mojo 0, BOTH
```

### Command-Line Arguments

```
mojo main.mojo [DAYS] [MODE]

DAYS (optional):
  - Omit or use '0' to run all days (1-12)
  - Single day: '5' runs day 5
  - Multiple days: '1,3,5' runs days 1, 3, and 5
  - Default: 0 (all days)

MODE (optional, case insensitive):
  - TEST: Use test input (test{NN}.txt)
  - FULL: Use full input (full{NN}.txt, default)
  - BOTH: Run both!
```

### Help

```bash
mojo main.mojo --help
```

## Notes

- Input files are read as strings; parse them as needed in your solution
- Return all answers as `String` types from both `partOne` and `partTwo`