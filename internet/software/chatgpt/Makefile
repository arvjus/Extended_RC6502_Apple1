SOURCES = chatgpt.asm

all: clean chatgpt.mon

sim: clean chatgpt.bin
	py65mon

upload: chatgpt.mon
	uploader_a1.py chatgpt.mon

dump: chatgpt.bin
	hexdump -C chatgpt.bin

chatgpt.mon: chatgpt.bin
	bintomon -v -l 0x0300 -r- chatgpt.bin >chatgpt.mon

chatgpt.bin: $(SOURCES)
	64tass --m6502 --nostart --output chatgpt.bin --list chatgpt.lst chatgpt.asm

clean:
	$(RM) chatgpt.bin chatgpt.mon chatgpt.lst 
