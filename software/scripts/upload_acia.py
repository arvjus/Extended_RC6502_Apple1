#!/usr/bin/env python3

import sys
import os
import time
import serial

def main():
    if len(sys.argv) < 3:
        print("Usage: upload_acia.py <binary_file> <start_addr_hex> [port] [baud]")
        sys.exit(1)

    filename = sys.argv[1]
    start_addr_str = sys.argv[2]
    serial_port = "/dev/ttyS1" if len(sys.argv) < 4 else sys.argv[3]
    baud_rate = 28800 if len(sys.argv) < 5 else int(sys.argv[4])
    
    try:
        start_addr = int(start_addr_str, 16)
    except ValueError:
        print(f"Error: invalid start address '{start_addr_str}' (must be hex, e.g. 300).")
        sys.exit(1)

    if not os.path.isfile(filename):
        print(f"Error: file '{filename}' not found.")
        sys.exit(1)

    file_size = os.path.getsize(filename)
    end_addr = start_addr + file_size
    checksum = 0     

    with open(filename, "rb") as f:
        data = f.read()

    print(f"Using port {serial_port} at {baud_rate} baud")
    
    try:
        with serial.Serial(serial_port, baud_rate, timeout=None) as ser:
            # Send 
            ser.write('r'.encode())
            time.sleep(0.005)  # 5ms delay per byte

            # Prepare bytes: start low, start high, end low, end high
            addresses = [
                start_addr & 0xFF,
                (start_addr >> 8) & 0xFF,
                end_addr & 0xFF,
                (end_addr >> 8) & 0xFF,
            ]

            # Send address bytes
            for b in addresses:
                ser.write(bytes([b]))
                time.sleep(0.005)  # 5ms delay per byte

            # Send file data
            start = time.time()
            for b in data:
                ser.write(bytes([b]))
                checksum = (checksum + b) & 0xFFFF
                time.sleep(0.002)  # 1ms delay per byte
            end = time.time()

            bps = len(data) * 10 / (end - start)   # approximate bit rate (8N1)
            print(f"Send {len(data)} bytes in {end - start:.2f}s " f"≈ {bps:.0f} baud")

            # Optionally flush if needed
            ser.flush()
            print(f"Address range: {start_addr:04X}-{end_addr:04X}, checksum: {checksum:04X}")
            print("Upload complete.")

    except serial.SerialException as e:
        print(f"Error opening/using serial port: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
