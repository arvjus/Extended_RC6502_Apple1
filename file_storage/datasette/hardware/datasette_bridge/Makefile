all:
	pcb2gcode 

upload:
	scp export/*.gcode thin:~/tmp

clean:
	rm -f *.svg export/*.gcode
