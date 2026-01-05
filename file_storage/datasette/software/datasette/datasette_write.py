#!/usr/bin/env python3
import sys
import serial
import os
import time
import argparse
import random

def main():
    parser = argparse.ArgumentParser(description='Upload files to datasette (6502-simulated)')
    parser.add_argument('files', nargs='+', help='Files to upload')
    parser.add_argument('-p', '--port', default='/dev/ttyS1', help='Serial port (default: /dev/ttyS1)')
    parser.add_argument('-d', '--delay', type=float, default=10.0,
                        help='Delay BETWEEN BYTES in milliseconds (default: 1.0 ms)')
    parser.add_argument('-j', '--jitter', type=float, default=0.0,
                        help='Random jitter added to delay (+/- value, milliseconds)')
    parser.add_argument('--flush', action='store_true',
                        help='Flush after each byte (slow but safest)')
    args = parser.parse_args()

    delay_s = args.delay / 1000.0
    jitter = args.jitter / 1000.0

    filenames = args.files
    port = args.port

    try:
        with serial.Serial(port, 28800, xonxoff=True) as ser:
            time.sleep(2)
            ser.write(b's')
            print("Sent sync command")

            for idx, filename in enumerate(filenames):
                if not os.path.exists(filename):
                    print(f"Error: File '{filename}' not found")
                    continue

                time.sleep(0.5 if idx == 1 else 0.1)

                file_size = os.path.getsize(filename)
                write_cmd = f"sw{file_size:04x}".encode('ascii')
                ser.write(write_cmd)
                print(f"Sent write command for '{filename}' ({file_size} bytes)")

                # send file one byte at a time
                with open(filename, "rb") as f:
                    for b in f.read():
                        ser.write(bytes([b]))

                        if args.flush:
                            ser.flush()

                        # deterministic delay + optional jitter
                        if jitter > 0:
                            d = delay_s + random.uniform(-jitter, jitter)
                            if d < 0:
                                d = 0
                            time.sleep(d)
                        else:
                            time.sleep(delay_s)

                print(f"Sent data for '{filename}'")

            ser.write(b'e')
            print("Sent end command")

        print("Transfer complete.")

    except serial.SerialException as e:
        print(f"Serial error: {e}")

if __name__ == "__main__":
    main()
