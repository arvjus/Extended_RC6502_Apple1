SOURCES = defs.asm bss.asm system.asm common.asm delay.asm uint2str.asm list.asm read.asm write.asm fdsh.asm

all: fdsh.mon

upload: fdsh.mon
	uploader_a1.py fdsh.mon

sim: clean fdsh.bin
	py65mon

dump: fdsh.bin
	hexdump -C fdsh.bin

img: fdsh.bin
	rm -f fdsh.img
	fdutil fdsh.img i 1
	fdutil fdsh.img wfdsh#1000 fdsh.bin
	fdutil fdsh.img l

fdsh.mon: fdsh.bin
	bintomon -v -l 0x8000 -r- fdsh.bin >fdsh.mon

fdsh.bin: $(SOURCES)
	64tass --m6502 --nostart --output fdsh.bin --list fdsh.lst fdsh.asm

clean:
	$(RM) fdsh.bin fdsh.mon fdsh.lst fdsh.img
