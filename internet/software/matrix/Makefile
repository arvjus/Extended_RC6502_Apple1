SOURCES = matrix.asm

all: clean matrix.mon

sim: clean matrix.bin
	py65mon

upload: matrix.mon
	uploader_a1.py matrix.mon

dump: matrix.bin
	hexdump -C matrix.bin

matrix.mon: matrix.bin
	bintomon -v -l 0x0300 -r- matrix.bin >matrix.mon

matrix.bin: $(SOURCES)
	64tass --m6502 --nostart --output matrix.bin --list matrix.lst matrix.asm

clean:
	$(RM) matrix.bin matrix.mon matrix.lst 
