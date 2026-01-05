; FlashDisk Shell
; Copyright (c) 2025 Arvid Juskaitis

; Key deffinitions
BS  = $08
CR  = $0D
ESC = $1B

; Device communication address
DEVICE_IN   = $C800
DEVICE_OUT  = $C801

; Command and marker definitions
CMD_LIST    = $01
CMD_READ    = $02
CMD_WRITE   = $03
CMD_STORE   = $04
CMD_DELETE  = $05
ACK         = $A0
NACK        = $AF
BODT        = $80       ; Begin of data transfer marker
EODT        = $8F       ; End of data transfer marker

RDY         = %10000000
BSY         = %01000000
DAT         = %00010000

; Status codes as return codes from subroutines
ST_RESET    = 0
ST_WIP      = 1
ST_DONE     = 2
ST_ABORT    = 3
ST_ERROR    = 4

