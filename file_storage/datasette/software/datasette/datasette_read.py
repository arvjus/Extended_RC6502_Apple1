#!/usr/bin/env python3
import sys
import serial
import termios
import tty
import select
import time
import argparse

def kbhit():
    dr, _, _ = select.select([sys.stdin], [], [], 0)
    return dr != []

def getch():
    return sys.stdin.read(1)

def main():
    parser = argparse.ArgumentParser(description='Read data from datasette')
    parser.add_argument('filename', help='Output filename')
    parser.add_argument('-p', '--port', default='/dev/ttyS1', help='Serial port (default: /dev/ttyS1)')
    
    args = parser.parse_args()
    filename = args.filename
    port = args.port

    old_settings = termios.tcgetattr(sys.stdin)

    try:
        tty.setcbreak(sys.stdin.fileno())
        ser = serial.Serial(port, 28800, timeout=0)
        time.sleep(2)  # Wait for device to reset and initialize
        ser.write(b'r')

        print("Press ESC to stop capture.")

        last_time = time.time()
        received_this_second = False

        with open(filename, "wb") as f:
            while True:
                data = ser.read(256)
                if data:
                    f.write(data)
                    received_this_second = True

                now = time.time()
                if now - last_time >= 1.0:
                    if received_this_second:
                        print('.', end='', flush=True)
                    received_this_second = False
                    last_time = now

                if kbhit() and getch() == '\x1b':
                    ser.write(b'x')
                    print("\nStopping.")
                    break

    except serial.SerialException as e:
        print(f"Serial error: {e}")
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)
        try:
            ser.close()
        except:
            pass

if __name__ == "__main__":
    main()

