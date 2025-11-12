SOURCES = system.asm gcd_lcm.asm 

all: clean gcd_lcm.mon

upload: gcd_lcm.mon
	uploader_a1.py gcd_lcm.mon

dump: gcd_lcm.bin
	hexdump -C gcd_lcm.bin

gcd_lcm.mon: gcd_lcm.bin
	bintomon -v -l 0x1000 -r- gcd_lcm.bin >gcd_lcm.mon

gcd_lcm.bin: $(SOURCES)
	64tass --m6502 --nostart --output gcd_lcm.bin --list gcd_lcm.lst gcd_lcm.asm

clean:
	$(RM) gcd_lcm.bin gcd_lcm.mon gcd_lcm.lst 
