SOURCES = loader.asm

all: clean loader.mon

sim: clean loader.bin
	py65mon

upload: loader.mon
	upload_a1.py loader.mon

dump: loader.bin
	hexdump -C loader.bin

loader.mon: loader.bin
	bintomon -v -l 0x0300 -r- loader.bin >loader.mon

loader.bin: $(SOURCES)
	64tass -D FIRMWARE=0 --m6502 --nostart --output loader.bin --list loader.lst loader.asm

clean:
	$(RM) loader.bin loader.mon loader.lst 
