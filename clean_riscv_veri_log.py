import re
import sys

# Ensure the script receives exactly two arguments
if len(sys.argv) != 3:
    print(f"Usage: python {sys.argv[0]} <input_filename> <output_filename>")
    sys.exit(1)

input_filename = sys.argv[1]
output_filename = sys.argv[2]

# Regex pattern to match RISC-V instructions
instruction_pattern = re.compile(r'^\s*core\s+\d+:\s+\S+\s+\(\S+\)\s+(\S+.*)$')

riscv_instructions = []

try:
    with open(input_filename, "r") as infile:
        for line in infile:
            match = instruction_pattern.match(line)
            if match:
                riscv_instructions.append(match.group(1))

    with open(output_filename, "w") as outfile:
        outfile.write("\n".join(riscv_instructions) + "\n")

    print(f"Process completed, created new file {output_filename}")

except FileNotFoundError:
    print(f"Could not find file '{input_filename}'")
