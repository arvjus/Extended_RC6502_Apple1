# FileStorage_RC6502_Apple1

This is a collection of HW / SW to provide file storage capabilty for RC6502 Apple1 Replica.
	
## Main Highlights
	* Uses W25Q64 chip to srore the data
	* Simple File system to keep files structured
	* Supported files: type $06 (regular binary), $F1 (Integer Basic, ProDOS file format)
	* Utility programs to prepare disk images or porsions of FS on regular OS (tested on Linux)			
	
## Status
	Quite stable, I use it on dayly basis
 
## Desired improvements
	* Better error handling. In most cases if user does input error or something unexpected happens in communication, the command is just silently ignored.
 	* Better performance in data transfer. It takes about 3 secs to load 1Kb of data.
 
## Screenshots

Main menu, list files:
![fdsh](https://github.com/arvjus/Extended_RC6502_Apple1/blob/main/gallery/fdsh.jpeg?raw=1)

Card in development - runnin on emulator:
![fdsh](https://github.com/arvjus/Extended_RC6502_Apple1/blob/main/gallery/emulator.jpeg?raw=1)

	 
