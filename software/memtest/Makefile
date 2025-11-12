SOURCES = memtest.asm

all: clean memtest.mon

sim: clean memtest.bin
	py65mon

upload: memtest.mon
	uploader_a1.py memtest.mon

dump: memtest.bin
	hexdump -C memtest.bin

memtest.mon: memtest.bin
	bintomon -v -l 0x0300 -r- memtest.bin >memtest.mon

memtest.bin: $(SOURCES)
	64tass --m6502 --nostart --output memtest.bin --list memtest.lst memtest.asm

clean:
	$(RM) memtest.bin memtest.mon memtest.lst 
