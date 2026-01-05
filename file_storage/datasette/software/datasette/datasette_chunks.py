#!/usr/bin/env python3
"""
Create chunks type 1 (header), type 2 (basic header), type 3 (payload), and type 4 (checksum) from input file.

Chunk format: size_low, size_high, type, data...

Creates files: <input_file>.1 (header chunk), <input_file>.20 (payload header), <input_file>.21 (payload data), <input_file>.3 (basic header chunk for type 2 only), <input_file>.4 (checksum chunk)

Usage: create_chunks.py <input_file> <address>
Address is given in hex without 0x prefix (e.g., 1000 for 0x1000)
"""

import sys
import argparse
from pathlib import Path


def create_header_chunk(file_type, filename):
    """
    Create a type 1 (header) chunk.
    
    Args:
        file_type: 1=runnable, 2=basic, 3=data
        filename: Name of the file (string)
    
    Returns:
        bytearray containing the complete chunk
    """
    chunk = bytearray()
    
    # Calculate length of following data (type + file_type + filename)
    filename_bytes = filename.encode('ascii')
    data_length = 1 + 1 + len(filename_bytes)  # type byte + file_type byte + filename
    
    # 1st and 2nd bytes: length (little endian)
    chunk.append(data_length & 0xFF)
    chunk.append((data_length >> 8) & 0xFF)
    
    # 3rd byte: type (always 1 for header)
    chunk.append(1)
    
    # 4th byte: file type
    chunk.append(file_type)
    
    # Rest: filename
    chunk.extend(filename_bytes)
    
    return chunk


def create_payload_header(start_address, data_length):
    """
    Create the header part of a type 2 (payload) chunk.
    
    Args:
        start_address: 16-bit start address
        data_length: length of the data that follows
    
    Returns:
        bytearray containing the 5-byte header
    """
    chunk = bytearray()
    
    # Calculate total length of chunk (type + start address + data)
    total_length = 1 + 2 + data_length  # type byte + 2 bytes for address + data
    
    # 1st and 2nd bytes: length (little endian)
    chunk.append(total_length & 0xFF)
    chunk.append((total_length >> 8) & 0xFF)
    
    # 3rd byte: type (always 2 for payload)
    chunk.append(2)
    
    # 4th and 5th bytes: start address (little endian)
    chunk.append(start_address & 0xFF)
    chunk.append((start_address >> 8) & 0xFF)
    
    return chunk


def create_basic_header_chunk(basic_header_data):
    """
    Create a type 3 (basic header) chunk.
    
    Args:
        basic_header_data: 512 bytes of basic header data
    
    Returns:
        bytearray containing the complete chunk
    """
    chunk = bytearray()
    
    # 1st byte: length low (always 1 for 513 bytes: type + 512 data)
    chunk.append(1)
    
    # 2nd byte: length high (always 2 for 513 bytes)
    chunk.append(2)
    
    # 3rd byte: type (always 3 for basic header)
    chunk.append(3)
    
    # Rest: 512 bytes of basic header data
    chunk.extend(basic_header_data)
    
    return chunk


def create_checksum_chunk(checksum):
    """
    Create a type 4 (checksum) chunk.
    
    Args:
        checksum: 16-bit checksum value
    
    Returns:
        bytearray containing the complete chunk
    """
    chunk = bytearray()
    
    # 1st byte: length low (always 3 for checksum: type + 2 bytes)
    chunk.append(3)
    
    # 2nd byte: length high (always 0)
    chunk.append(0)
    
    # 3rd byte: type (always 4 for checksum)
    chunk.append(4)
    
    # 4th and 5th bytes: checksum (little endian)
    chunk.append(checksum & 0xFF)
    chunk.append((checksum >> 8) & 0xFF)
    
    return chunk


def calculate_checksum(chunks):
    """
    Calculate checksum as 16-bit modulo 65536 addition of all bytes in chunks.
    
    Args:
        chunks: list of bytearrays to calculate checksum for
    
    Returns:
        16-bit checksum value
    """
    checksum = 0
    for chunk in chunks:
        for byte in chunk:
            checksum = (checksum + byte) % 65536
    return checksum


def main():
    parser = argparse.ArgumentParser(
        description='Create datasette chunks from input file. Creates chunks with separated payload header and data.'
    )
    parser.add_argument('input_file', help='Input file to process')
    parser.add_argument('address', type=lambda x: int(x, 16),
                        help='Start address in hex without 0x prefix (e.g., 1000 for 0x1000)')
    parser.add_argument('-t', '--type', type=int, choices=[1, 2, 3], default=1,
                        help='File type: 1=runnable, 2=basic, 3=data (default: 1)')
    parser.add_argument('-v', '--verbose', action='store_true',
                        help='Verbose output')
    
    args = parser.parse_args()
    
    # Read input file
    input_path = Path(args.input_file)
    if not input_path.exists():
        print(f"Error: Input file '{args.input_file}' not found", file=sys.stderr)
        return 1
    
    with open(input_path, 'rb') as f:
        file_data = f.read()
    
    # Get filename from input file (stem without extension)
    file_name = input_path.stem
    if len(file_name) > 255:
        print(f"Warning: Filename truncated to 255 characters", file=sys.stderr)
        file_name = file_name[:255]
    
    # Create output files
    base_name = input_path.stem
    # Common files
    header_output = input_path.parent / f"{base_name}.1"
    payload_output_1 = input_path.parent / f"{base_name}.20"
    payload_output_2 = input_path.parent / f"{base_name}.21"
    checksum_output = input_path.parent / f"{base_name}.4"
    
    if args.type == 2:
        basic_header_output = input_path.parent / f"{base_name}.3"
    
    # Create header chunk (type 1)
    header_chunk = create_header_chunk(args.type, file_name)
    
    if args.verbose:
        print(f"Created header chunk: {len(header_chunk)} bytes")
        print(f"  Type: {args.type} ({'runnable' if args.type == 1 else 'basic' if args.type == 2 else 'data'})")
        print(f"  Name: {file_name}")
    
    # Write header chunk to .1 file
    with open(header_output, 'wb') as f:
        f.write(header_chunk)
    
    if args.type == 2:
        # For basic files, split the data
        if len(file_data) < 512:
            print(f"Error: Basic file must be at least 512 bytes, got {len(file_data)}", file=sys.stderr)
            return 1
        
        basic_header_data = file_data[:512]
        payload_data = file_data[512:]
        
        # Create payload header and data
        payload_header = create_payload_header(args.address, len(payload_data))
        payload_data_full = payload_data
        
        if args.verbose:
            print(f"Created payload header: {len(payload_header)} bytes")
            print(f"  Start address: 0x{args.address:04X}")
            print(f"  Data length: {len(payload_data_full)} bytes")
        
        # Write payload header to .30 and data to .31
        with open(payload_output_1, 'wb') as f:
            f.write(payload_header)
        with open(payload_output_2, 'wb') as f:
            f.write(payload_data_full)
        
        # Create basic header chunk (type 3)
        basic_header_chunk = create_basic_header_chunk(basic_header_data)
        
        if args.verbose:
            print(f"Created basic header chunk: {len(basic_header_chunk)} bytes")
            print(f"  Basic header length: {len(basic_header_data)} bytes")

        # Write basic header chunk to .3 file
        with open(basic_header_output, 'wb') as f:
            f.write(basic_header_chunk)
        
        # Calculate checksum on header, basic header, payload header, and payload data
        checksum = calculate_checksum([header_chunk, payload_header, payload_data_full, basic_header_chunk])
        
        # Create checksum chunk (type 4)
        checksum_chunk = create_checksum_chunk(checksum)
        
        if args.verbose:
            print(f"Created checksum chunk: {len(checksum_chunk)} bytes")
            print(f"  Checksum: 0x{checksum:04X} ({checksum})")
        
        # Write checksum chunk to .4 file
        with open(checksum_output, 'wb') as f:
            f.write(checksum_chunk)
        
        print(f"Created {header_output} ({len(header_chunk)} bytes)")
        print(f"Created {payload_output_1} ({len(payload_header)} bytes)")
        print(f"Created {payload_output_2} ({len(payload_data_full)} bytes)")
        print(f"Created {basic_header_output} ({len(basic_header_chunk)} bytes)")
        print(f"Created {checksum_output} ({len(checksum_chunk)} bytes)")
        print(f"Checksum: 0x{checksum:04X}")
        
    else:
        # For non-basic files
        # Create payload header and data
        payload_header = create_payload_header(args.address, len(file_data))
        payload_data = file_data
        
        if args.verbose:
            print(f"Created payload header: {len(payload_header)} bytes")
            print(f"  Start address: 0x{args.address:04X}")
            print(f"  Data length: {len(payload_data)} bytes")
        
        # Write payload header to .20 and data to .21
        with open(payload_output_1, 'wb') as f:
            f.write(payload_header)
        with open(payload_output_2, 'wb') as f:
            f.write(payload_data)
        
        # Calculate checksum on header, payload header, and payload data
        checksum = calculate_checksum([header_chunk, payload_header, payload_data])
        
        # Create checksum chunk (type 4)
        checksum_chunk = create_checksum_chunk(checksum)
        
        if args.verbose:
            print(f"Created checksum chunk: {len(checksum_chunk)} bytes")
            print(f"  Checksum: 0x{checksum:04X} ({checksum})")
        
        # Write checksum chunk to .4 file
        with open(checksum_output, 'wb') as f:
            f.write(checksum_chunk)
        
        print(f"Created {header_output} ({len(header_chunk)} bytes)")
        print(f"Created {payload_output_1} ({len(payload_header)} bytes)")
        print(f"Created {payload_output_2} ({len(payload_data)} bytes)")
        print(f"Created {checksum_output} ({len(checksum_chunk)} bytes)")
        print(f"Checksum: 0x{checksum:04X}")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
