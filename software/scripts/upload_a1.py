#!/usr/bin/python3

import serial
import time
import sys

def send_to_serial(port, baudrate, wozmon_lines):
    """Send WozMon lines to the Apple-1 over a serial connection."""

    with serial.Serial(port, baudrate, timeout=1) as ser:
        timeout = time.time() + 3
        while timeout > time.time():
            if ser.in_waiting > 0:
                response = ser.read(ser.in_waiting).decode('ascii', errors='ignore')
                print(f"RX: {response}")

        for line in wozmon_lines:
            for char in line + "\r":  # Add CR to the end of each line
                ser.write(char.encode('ascii'))
                time.sleep(0.05)  # 100 ms per character to avoid overflow
            print(f"TX: {line}", end='')
            time.sleep(0.2)  # 500 ms per line to avoid overflow

            # Print any response from the WozMon
            while ser.in_waiting > 0:
                response = ser.read(ser.in_waiting).decode('ascii', errors='ignore')
                print(f"RX: {response}", end='')

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: upload_a1.py <filename> [port] [baud]")
        sys.exit(1)

    file = sys.argv[1]
    serial_port = "/dev/ttyUSB0" if len(sys.argv) < 3 else sys.argv[2]
    baud_rate = 250000 if len(sys.argv) < 4 else int(sys.argv[3])
    
    # Read input file
    try:
        with open(file, "r") as f:
            wozmon_lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File {file} not found.")
        sys.exit(1)

    # Send data to serial
    try:
        send_to_serial(serial_port, baud_rate, ["", ""] + wozmon_lines)
        print("Upload complete. Start address is ", wozmon_lines[0].split(':')[0])
    except serial.SerialException as e:
        print(f"Error: {e}")
        sys.exit(1)

