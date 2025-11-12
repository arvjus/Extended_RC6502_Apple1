PLATFORM=APPLE1

all: jmon.bin

jmon.bin: jmon.o
	ld65 -C /usr/share/cc65/cfg/none.cfg -vm -m jmon.map -o jmon.bin jmon.o

jmon.o:	jmon.s disasm.s miniasm.s trace.s info.s memtest4.s
	ca65 -D$(PLATFORM) -g -l jmon.lst jmon.s

clean:
	$(RM) jmon.o jmon.lst jmon.map jmon.bin 
