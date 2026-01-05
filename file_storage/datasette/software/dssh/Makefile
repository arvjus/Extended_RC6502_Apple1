SOURCES = defs.asm bss.asm system.asm common.asm delay.asm uint2str.asm read.asm write.asm dssh.asm 
REAL_HW = 1     # 1=Apple1 or 0=py65mon
DEBUG = 0       # 1=Show traces in data exchange

all: dssh.bin

upload: dssh.mon
	#upload_a1.py dssh.mon
	upload_acia.py dssh.bin 7000

sim: clean dssh.bin
	py65mon

dssh.mon: dssh.bin
	bintomon -v -l 0x7000 -r- dssh.bin >dssh.mon

dssh.bin: $(SOURCES)
	64tass -D FIRMWARE=0 -D REAL_HW=$(REAL_HW) -D DEBUG=$(DEBUG) --m6502 --nostart --output dssh.bin --list dssh.lst dssh.asm

clean:
	$(RM) dssh.bin dssh.mon dssh.lst 
