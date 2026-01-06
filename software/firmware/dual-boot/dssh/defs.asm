; Datasette Shell
; Copyright (c) 2025 Arvid Juskaitis

; Protocol definitions
CHUNK_TYPE_HEADER = 1
CHUNK_TYPE_PAYLOAD = 2
CHUNK_TYPE_BASIC = 3
CHUNK_TYPE_CHECKSUM = 4

FILE_TYPE_RUNNABLE = 1
FILE_TYPE_BASIC = 2
FILE_TYPE_DATA = 3

CMD_SYNC = 's'
CMD_WRITE = 'w'
CMD_READ = 'r'
CMD_END = 'e'
CMD_CANCEL = 'x'

; Keyboard input
KEY_READ = 'r'
KEY_CANCEL = 'c'

; Flow control
XON = $11
XOFF = $13

.if ! FIRMWARE
; ACIA registers
ACIA_CTRL       = $c000
ACIA_STATUS     = $c000
ACIA_DATA       = $c001
.endif

; Key deffinitions
BS  = $08
CR  = $0D
ESC = $1B

