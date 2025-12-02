#!/usr/bin/env python3
"""Generate template solution files for Advent of Code days 01-12. Claude 4.5 Sonnet."""

import os

TEMPLATE = '''from solution import Solution

@fieldwise_init
struct Solution{day:02d}(Solution):
    
    fn partOne(self, input_file: String) -> String:
        return "0"

    fn partTwo(self, input_file: String) -> String:
        return "0"
'''

def main():
    output_dir = "."
    os.makedirs(output_dir, exist_ok=True)

    answer = input("Are you sure you want to continue resetting all solutions? Y/N")
    if answer == 'Y':
    
        for day in range(1, 13):
            filename = os.path.join(output_dir, f"day{day:02d}.mojo")
            content = TEMPLATE.format(day=day)
        
            with open(filename, "w") as f:
                f.write(content)
        
            print(f"Created {filename}")

if __name__ == "__main__":
    main()
