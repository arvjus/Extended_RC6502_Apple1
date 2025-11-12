
CFLAGS = -O -t none -C ram.cfg

SRC_C = test.c
OBJ_C = $(SRC_C:.c=.o)
OUT = test

all: $(OUT).mon

$(OUT).mon: $(OUT)
	bintomon -v -l 0x0300 -r- $(OUT) >$(OUT).mon	

%.o: %.c
	cl65 $(CFLAGS) -S -o $(addsuffix _c.s, $(basename $< .c)) $<
	cl65 $(CFLAGS) -c -o $@ $<

$(OUT): $(OBJ_C) $(OBJ_ASM) 
	ld65 -C ram.cfg -o $(OUT) -m $(OUT).map $(OBJ_C) ../lib/a1c.lib

clean:
	rm -f $(OUT) $(OUT).map $(OUT).mon *_c.s *.o 
	 
