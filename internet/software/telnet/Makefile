SOURCES = telnet.asm

all: clean telnet.mon

sim: clean telnet.bin
	py65mon

upload: telnet.mon
	uploader_a1.py telnet.mon

dump: telnet.bin
	hexdump -C telnet.bin

telnet.mon: telnet.bin
	bintomon -v -l 0x0300 -r- telnet.bin >telnet.mon

telnet.bin: $(SOURCES)
	64tass --m6502 --nostart --output telnet.bin --list telnet.lst telnet.asm

clean:
	$(RM) telnet.bin telnet.mon telnet.lst 
