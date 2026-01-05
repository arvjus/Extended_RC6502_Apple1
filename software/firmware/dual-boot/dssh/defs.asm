; Datasette Shell
; Copyright (c) 2025 Arvid Juskaitis

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

