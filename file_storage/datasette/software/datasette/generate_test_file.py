#!/usr/bin/env python3
"""
Simple test file generator that creates files with repeating hex values 0x00-0xFF.
Usage: python generate_test_file.py <size> [output_file]
Size can be specified in bytes (e.g., 512) or kilobytes (e.g., 1kb, 2KB)
Output defaults to stdout if no file specified.
"""

import sys
import re

def parse_size(size_str):
    """Parse size string and return size in bytes."""
    size_str = size_str.strip().lower()
    
    # Check if it's in KB format
    match = re.match(r'^(\d+(?:\.\d+)?)\s*(kb|k)$', size_str)
    if match:
        value = float(match.group(1))
        return int(value * 1024)
    
    # Otherwise treat as bytes
    try:
        return int(size_str)
    except ValueError:
        raise ValueError(f"Invalid size format: {size_str}")

def generate_test_data(size_bytes, output_file=None):
    """Generate test data with repeating 0-f pattern as ASCII hex."""
    # Generate ASCII hex pattern: "0123456789abcdef"
    pattern = '0123456789abcdef'
    pattern_len = len(pattern)
    
    full_cycles = size_bytes // pattern_len
    remainder = size_bytes % pattern_len
    
    # Build the output
    output = pattern * full_cycles
    if remainder > 0:
        output += pattern[:remainder]
    
    # Write to file or stdout
    if output_file:
        with open(output_file, 'w') as f:
            f.write(output)
        print(f"Generated {output_file} with {len(output)} bytes", file=sys.stderr)
    else:
        sys.stdout.write(output)
        sys.stdout.flush()

def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_test_file.py <size> [output_file]", file=sys.stderr)
        print("Examples:", file=sys.stderr)
        print("  python generate_test_file.py 512           # output to stdout", file=sys.stderr)
        print("  python generate_test_file.py 1kb           # output to stdout", file=sys.stderr)
        print("  python generate_test_file.py 2KB test.txt  # output to file", file=sys.stderr)
        sys.exit(1)
    
    size_str = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    try:
        size_bytes = parse_size(size_str)
        generate_test_data(size_bytes, output_file)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
