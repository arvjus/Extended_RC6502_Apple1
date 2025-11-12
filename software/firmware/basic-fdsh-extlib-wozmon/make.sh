#!/bin/sh

make clean all RESET=WOZMON
cat apple1_00.bin > apple1_00_01.bin
make clean all RESET=FDSH
cat apple1_01.bin >>apple1_00_01.bin
