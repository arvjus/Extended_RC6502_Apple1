# Name of your sketch (without .ino)
SKETCH = datasette

# Fully Qualified Board Name (from Arduino IDE log)
FQBN = MiniCore:avr:328:bootloader=uart0,eeprom=keep,baudrate=default,variant=modelPB,BOD=disabled,LTO=Os_flto,clock=16MHz_external

# Serial port for upload
PORT = /dev/ttyUSB0

# Optional build directory (keeps things tidy)
BUILD_DIR = build

all: compile

compile:
	arduino-cli compile \
	  --fqbn $(FQBN) \
	  --build-path $(BUILD_DIR) \
	  $(SKETCH).ino

upload: compile
	avrdude -c usbtiny -p atmega328pb -U flash:w:$(BUILD_DIR)/$(SKETCH).ino.hex:i

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all compile upload clean

