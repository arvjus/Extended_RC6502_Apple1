#!/bin/sh

make clean all FDSH=1 DSSH=0
cat apple1_00.bin > apple1_00_01.bin
make clean all FDSH=0 DSSH=1
cat apple1_01.bin >>apple1_00_01.bin
