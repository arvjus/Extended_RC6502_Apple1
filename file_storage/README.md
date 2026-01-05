# File storage

There few ways to store programs to / load from:

## Read/write memory direct from PC via serial port
There is an application loader, built in EPROM which helps to manipulate memory from remote host. It is useful for cross-development- just by running "make upload" in any a1 program, the program is ready for testing within few seconds. 

## Flash-memory disk
Files are stored in flash-memory chip, FDSH program helps to manipulate contents of file system. FDSH is loaded automatically after power on (dual boot).

## C64 Datasette
Files are stored in C64 Datasette tape recorder, DSSH program helps to store / load files. DSSH is loaded automatically after power on (dual boot).

