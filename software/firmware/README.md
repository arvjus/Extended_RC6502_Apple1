
28c256 could contain 4x 8k images, we'll use two banks:

a13=0,a14=0 - basic-wozmon
a13=1,a14=1 - jmon-wozmon

a15 should always set to 1 for any fimware image while programming

$ 28C256-programmer.py /dev/ttyACM0 1 check
$ 28C256-programmer.py /dev/ttyACM0 1 write apple1_00_01.bin

