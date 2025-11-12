SOURCES = serial.asm

all: clean serial.mon

sim: clean serial.bin
	py65mon

upload: serial.mon
	uploader_a1.py serial.mon

dump: serial.bin
	hexdump -C serial.bin

serial.mon: serial.bin
	bintomon -v -l 0x0300 -r- serial.bin >serial.mon

serial.bin: $(SOURCES)
	64tass --m6502 --nostart --output serial.bin --list serial.lst serial.asm

clean:
	$(RM) serial.bin serial.mon serial.lst 
