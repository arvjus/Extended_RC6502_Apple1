This module add serial communication, based on M6850B ACIA 

It has fixed 28800 baud rate 

Connect from host (linux):
picocom --echo --omap crcrlf -b 28800 /dev/ttyUSB1
	
	
There are some programs already using this serial interface:
- serial
- loader
- internet/telnet
- internet/chatgpt
- internet/matrix
			
