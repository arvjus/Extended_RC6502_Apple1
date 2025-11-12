PLATFORM=APPLE1

all: apple1_11.bin

apple1_11.bin: apple1.bin
	dd if=apple1.bin of=apple1_11.bin bs=1 skip=32768

apple1.bin: apple1.o
	ld65 -C apple1_11.cfg -m apple1.map -o apple1.bin apple1.o

apple1.o: jmon.asm disasm.asm trace.asm memtest4.asm wozmon.asm
	ca65 -D$(PLATFORM) -l apple1.lst -o apple1.o jmon.asm 

clean:
	$(RM) apple1.o apple1.lst apple1.map apple1.bin apple1_11.bin
