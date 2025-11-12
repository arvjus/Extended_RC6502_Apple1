all: apple1_00 apple1_11

apple1_00: compile
	ld65 -m apple1.map -o apple1_00.bin apple1.o -C apple1_00.cfg

apple1_11: compile
	ld65 -m apple1.map -o apple1_11.bin apple1.o -C apple1_11.cfg

compile:
	ca65 -l apple1.lst apple1.asm

clean:
	@echo "Cleaning up..."
	rm -f *.o *.bin *.map *.lst
