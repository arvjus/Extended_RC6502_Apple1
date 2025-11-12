ASFLAGS = -t none

all: lib

lib: crt0.s extlib.s
	ca65 $(ASFLAGS) crt0.s
	ca65 $(ASFLAGS) extlib.s
	ar65 a a1c.lib crt0.o extlib.o

clean:
	rm -f crt0.o extlib.o
	 
