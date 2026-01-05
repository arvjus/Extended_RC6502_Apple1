#!/usr/bin/env python3
import sys
import serial
import termios
import tty
import select
import time
import string
import argparse

def kbhit():
    dr, _, _ = select.select([sys.stdin], [], [], 0)
    return dr != []

def getch():
    return sys.stdin.read(1)

def printable(c: int) -> str:
    """Convert a byte to printable ASCII or '.'"""
    ch = chr(c)
    return ch if ch in string.printable and c >= 0x20 else '.'

def main():
    parser = argparse.ArgumentParser(description='Debug datasette communication')
    parser.add_argument('-p', '--port', default='/dev/ttyS1', help='Serial port (default: /dev/ttyS1)')
    parser.add_argument('string', nargs='?', help='String to send as series of keypresses (optional)')
    
    args = parser.parse_args()
    port = args.port

    old_settings = termios.tcgetattr(sys.stdin)

    try:
        tty.setcbreak(sys.stdin.fileno())
        ser = serial.Serial(port, 28800, xonxoff=True, timeout=0)
        
        # If string argument is provided, send it and exit
        if args.string:
            time.sleep(2)  # Wait for device to reset and initialize
            for ch in args.string:
                ser.write(bytes([ord(ch)]))
                #time.sleep(0.01)  # Small delay between characters
            ser.flush()
        
        mode = 'hex'  # 'char' or 'hex'
        print("Debug active. Press ESC to quit, 'c' for char mode, 'h' for hex mode.")
        print("Mode: HEX")
        print("HEX                                              ASCII")
        print("-" * 65)
        
        buffer = bytearray()

        while True:
            # Read from serial
            data = ser.read(256)
            if data:
                if mode == 'char':
                    # Character mode: print each character immediately
                    for b in data:
                        sys.stdout.write(printable(b))
                    sys.stdout.flush()
                else:
                    # Hex mode: buffer and print 16 bytes per line
                    buffer.extend(data)
                    
                    # Print complete 16-byte lines immediately
                    while len(buffer) >= 16:
                        chunk = buffer[:16]
                        del buffer[:16]
                        
                        hex_part = " ".join(f"{b:02X}" for b in chunk)
                        asc_part = "".join(printable(b) for b in chunk)
                        
                        print(f"{hex_part:<48} {asc_part}", flush=True)

            # Handle keyboard input
            if kbhit():
                ch = getch()

                if ch == '\x1b':  # ESC
                    if buffer:
                        hex_part = " ".join(f"{b:02X}" for b in buffer)
                        asc_part = "".join(printable(b) for b in buffer).ljust(16)
                        print(f"{hex_part:<48} {asc_part}")
                    print("\nExiting.")
                    break
                elif ch == 'c':
                    mode = 'char'
                    buffer.clear()
                    print("\n[Mode: CHAR]")
                elif ch == 'h':
                    if mode != 'hex':
                        mode = 'hex'
                        print("\n[Mode: HEX]")
                        print("HEX                                              ASCII")
                        print("-" * 65)
                    # else already hex
                else:
                    # Send keyboard char to serial
                    ser.write(bytes([ord(ch)]))

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
