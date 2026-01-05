REAL_HW = 1     # 1=Apple1 or 0=py65mon
MOCK_HW = 0
DEBUG = 0       # 1=Show traces in data exchange

FDSH ?= 1
ifeq ($(FDSH),1)
OUTFILE = apple1_00.bin
endif
DSSH ?= 0
ifeq ($(DSSH),1)
OUTFILE = apple1_01.bin
endif

SOURCES = apple1.asm bss.asm \
    fdsh/fdsh.asm fdsh/defs.asm fdsh/common.asm fdsh/delay.asm fdsh/list.asm fdsh/read.asm fdsh/write.asm fdsh/delete.asm \
    dssh/dssh.asm dssh/defs.asm dssh/common.asm dssh/delay.asm dssh/read.asm dssh/write.asm \
    loader/loader.asm \
    extlib/str2uint.asm extlib/uint2str.asm extlib/ansiterm.asm extlib/conio.asm \
    wozmon/wozmon.asm 

all: basic/a1basic.bin apple1.bin $(OUTFILE)

$(OUTFILE): basic/a1basic.bin apple1.bin
	cp basic/a1basic.bin $@
	cat apple1.bin >>$@

basic/a1basic.bin: basic/a1basic.asm
	ca65 -l basic/a1basic.lst basic/a1basic.asm
	ld65 -m basic/a1basic.map -o basic/a1basic.bin basic/a1basic.o -C basic/a1basic.cfg

apple1.bin: $(SOURCES)
	64tass -D FIRMWARE=1 -D MOCK_HW=$(MOCK_HW) -D REAL_HW=$(REAL_HW) -D DEBUG=$(DEBUG) -D FDSH=$(FDSH) -D DSSH=$(DSSH) --m6502 --nostart --output apple1.bin --list apple1.lst apple1.asm
	./listaddr.py

clean:
	$(RM) basic/a1basic.bin basic/a1basic.o basic/a1basic.lst basic/a1basic.map \
	apple1.bin apple1.lst apple1_0?.bin 
