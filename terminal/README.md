Original RC6502 Apple1 Replica does not have display or keyboard, a standard solution is to used a terminal emulator on PC and connect it through USB port an Arduino Pico.
	
I took a different approach, I created a "dumb" terminal, like VT100 and connected it via UART interface. This terminal is not 100% ANSI compatible, but it supports colors, cursor movement, etc.
I faced a problem here- there was a socket for Arduino Pico on main board, but RX, TX pins were unavailable - USB port was using these pins. So, I created an adaptor, based on ATMega328.

