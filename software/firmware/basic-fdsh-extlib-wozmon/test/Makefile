SOURCES = test_extlib.asm 

all: clean test_extlib.mon

upload: test_extlib.mon
	uploader_a1.py test_extlib.mon

dump: test_extlib.bin
	hexdump -C test_extlib.bin

test_extlib.mon: test_extlib.bin
	bintomon -v -l 0x1000 -r- test_extlib.bin >test_extlib.mon

test_extlib.bin: $(SOURCES)
	64tass --m6502 --nostart --output test_extlib.bin --list test_extlib.lst test_extlib.asm

clean:
	$(RM) test_extlib.bin test_extlib.mon test_extlib.lst 
