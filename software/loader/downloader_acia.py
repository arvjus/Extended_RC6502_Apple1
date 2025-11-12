#!/usr/bin/env python3

import sys
import time
import serial

def main():
    if len(sys.argv) < 4:
        print("Usage: downloader_acia.py <binary_file> <start_addr_hex> <stop_addr_hex> [port] [baud]")
        sys.exit(1)

    filename = sys.argv[1]
    start_addr_str = sys.argv[2]
    stop_addr_str = sys.argv[3]
    serial_port = "/dev/ttyS0" if len(sys.argv) < 5 else sys.argv[4]
    baud_rate = 28800 if len(sys.argv) < 6 else int(sys.argv[5])
    
    # Convert hex addresses to integers
    try:
        start_addr = int(start_addr_str, 16)
    except ValueError:
        print(f"Error: invalid start address '{start_addr_str}' (must be hex, e.g. 300).")
        sys.exit(1)

    try:
        stop_addr = int(stop_addr_str, 16)
    except ValueError:
        print(f"Error: invalid stop address '{stop_addr_str}' (must be hex, e.g. 300).")
        sys.exit(1)

    # Calculate how many bytes we expect to receive (stop address is exclusive)
    length = stop_addr - start_addr
    if length <= 0:
        print("Error: stop address must be strictly greater than start address.")
        sys.exit(1)

    # Let the user know what's happening
    print(f"Reading {length} bytes from address range {start_addr:04X}-{stop_addr:04X}")
    print(f"Using port {serial_port} at {baud_rate} baud")

    try:
        with serial.Serial(serial_port, baud_rate, timeout=15) as ser:
            # Send command to initiate data read from the device
            ser.write('t'.encode('ascii'))
            time.sleep(0.01)

            # Prepare bytes for start and stop addresses
            # The device must interpret 'stop_addr' as exclusive on its side.
            addresses = [
                start_addr & 0xFF,
                (start_addr >> 8) & 0xFF,
                stop_addr & 0xFF,
                (stop_addr >> 8) & 0xFF,
            ]

            # Send address bytes
            for b in addresses:
                ser.write(bytes([b]))
                time.sleep(0.005)  # slight delay

            # Now read the data
            start = time.time()
            received_data = ser.read(length)
            end = time.time()
            if len(received_data) != length:
                print(f"Error: expected {length} bytes, got {len(received_data)} bytes.")
                sys.exit(1)

            bps = length * 10 / (end - start)   # approximate bit rate (8N1)
            print(f"Received {length} bytes in {end - start:.2f}s " f"≈ {bps:.0f} baud")

            # Calculate a checksum
            checksum = 0
            for b in received_data:
                checksum = (checksum + b) & 0xFFFF

            # Write the received bytes to file
            with open(filename, "wb") as f:
                f.write(received_data)

            print(f"Data read complete. Checksum: {checksum:04X}")
            print(f"Saved to file: {filename}")

    except serial.SerialException as e:
        print(f"Error opening/using serial port: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
