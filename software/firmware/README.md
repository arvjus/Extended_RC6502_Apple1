Firmware of RC6502 Apple1 Replica
Copyright (c) 2025 Arvid Juskaitis

Address space - $E000 - $FFFF (EPROM) 

# Entry points for different programs
```
$E000 - A1 Integer Basic
$F000 - FDSH (FlashDisk Shell)
$F900 - ExtLib (Common I/O routines)
$FF00 - WozMon
```
# Usage of ZP
All programs on this EPROM uses ZP. bss.asm defines locations of ZP, while trying to co-exist and not overlap in memory.


28c256 could contain 4x 8k images, we'll use two banks:

a13=0,a14=0 - basic-wozmon
a13=1,a14=1 - jmon-wozmon

a15 should always set to 1 for any fimware image while programming

$ 28C256-programmer.py /dev/ttyACM0 1 check
$ 28C256-programmer.py /dev/ttyACM0 1 write apple1_00_01.bin

