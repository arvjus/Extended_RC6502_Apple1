Reference project
https://www.pagetable.com/?p=964


*** Each byte is encoded as:

Segment	Pattern (pulse pairs)	Meaning
Byte marker	L / M	Start of byte
Bits 0–7	S / M = 0
M / S = 1	Data bits (LSB first)
Parity bit	S / M or M / S	Inverted odd parity

Pulse durations (nominal):

Pulse	Duration (µs)
Short	366
Medium	532
Long	698


HW connections
Pin	Signal	Direction	Description
1	GND	—	Ground
2	+5 V	—	Power supply for the tape motor control and logic
3	Motor Control	Output (from C64)	Controls the cassette motor. Set 5 V to turn it on.
4	Read (Tape Data In)	Input (to C64)	Analog data from the tape head (goes through the internal amplifier in the Datasette)
5	Write (Tape Data Out)	Output (from C64)	Data written to tape (digital pulses converted to magnetic signal by the write head)
6	Sense / Switch	Input (to C64)	Detects if the Play key is pressed. When Play is pressed, this pin is connected to ground inside the Datasette.

Building
build and upload with USBTinyISP
