#!/usr/bin/python3

import re

# Read the 64tass list file
with open("apple1.lst", "r") as file:
    lines = file.readlines()

# Dictionary to store label names and addresses
entry_labels = {}

# Regex pattern to match labels and their addresses
pattern = re.compile(r"^\.(\w{4})\s+(entry_\w+):")

for line in lines:
    match = pattern.search(line)
    if match:
        address_hex = f"${match.group(1)}"
        entry_labels[match.group(2)] = (address_hex)

# Print the results
for label, (addr_hex) in entry_labels.items():
    name = label.replace("entry_", "").upper()
    print(f"{name} = {addr_hex}")

