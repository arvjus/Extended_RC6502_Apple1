# matrix chat program, uses M6850B ACIA + ESP8266
Copyright (c) 2025 Arvid Juskaitis

Connect from host (linux):
picocom --echo --omap crcrlf -b 28800 /dev/ttyUSB1

## Example sessions:

### get a message
```
!CLEAR
!GET https://matrix.org/_matrix/client/v3/rooms/$(MATRIX-ROOM)/messages?dir=f&limit=10&from=$(MATRIX-POSITION)
!HEAD Authorization: Bearer $(MATRIX-TOKEN)
!HEAD Content-Type: application/json
!FILTER MATRIX-FILTER
!SEND
```
### put a message
```
!CLEAR
!PUT https://matrix.org/_matrix/client/v3/rooms/$(MATRIX-ROOM)/send/m.room.message/$(RANDOM)
!HEAD Authorization: Bearer $(MATRIX-TOKEN)
!HEAD Content-Type: application/json
!BODY $(MATRIX-BODY)
!FILTER SILENT-FILTER
ir vel kommunikacija! 
```
## Screenshots

### Chat program (matrix.org):
![matrix-chat](https://github.com/arvjus/Extended_RC6502_Apple1/blob/main/gallery/matrix-chat.jpeg?raw=1)
