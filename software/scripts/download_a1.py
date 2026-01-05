#!/usr/bin/python3

import serial
import time
import sys, re

def capture_serial_output(port, baudrate, output_file, lines):
    """Capture Apple-1 output from serial after sending a command."""
    with serial.Serial(port, baudrate, timeout=1) as ser:
        print("Waiting for 'RC6502 Apple 1 Replica'...")
        
        # Wait for the presentation string
        while True:
            if ser.in_waiting > 0:
                response = ser.read(ser.in_waiting).decode('ascii', errors='ignore')
                print(f"RX: {response}", end='')
                if "RC6502 Apple 1 Replica" in response:
                    break
                time.sleep(0.1)
        
        time.sleep(1)
        for line in lines:
            for char in line + "\r":  # Add CR to the end of each line
                ser.write(char.encode('ascii'))
                time.sleep(0.1)  # 100 ms per character to avoid overflow
            print(f"TX: {line}", end='')
            time.sleep(2)  # 500 ms per line to avoid overflow

        collected_lines = []
        last_received_time = time.time()
        
        # Capture response
        done = False
        while not done:
            if ser.in_waiting > 0:
                response = ser.read(ser.in_waiting).decode('ascii', errors='ignore').replace('\r', '\n')
                print(f"RX: {response}", end='')
                last_received_time = time.time()
                
                for line in response.split("\n"):
                    line = line.rstrip()  
                    collected_lines.append(line)
                
            if time.time() - last_received_time > 3:
                print("Timeout reached. Stopping capture.")
                break  # Stop capturing when timeout is reached
            
            time.sleep(0.1)  # Prevent CPU overload
        
        # Write collected lines to file
        first = True
        with open(output_file, "w") as f:
            for line in collected_lines:
                if line == "LIST" or line == ">":
                    continue
                if line and re.match(r"^\s*\d+", line):
                    if not first:
                        f.write("\n")
                    f.write(line)
                else:
                    f.write("" + line.lstrip())
                first = False
                        
        print("Capture complete. Data saved to:", output_file)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: download_a1.py <output_file> [port] [baud] [command]")
        sys.exit(1)

    output_file = sys.argv[1]
    serial_port = "/dev/ttyUSB0" if len(sys.argv) < 3 else sys.argv[2]
    baud_rate = 250000 if len(sys.argv) < 4 else int(sys.argv[3])

    try:
        capture_serial_output(serial_port, baud_rate, output_file, ["LIST"])
    except serial.SerialException as e:
        print(f"Error: {e}")
        sys.exit(1)
