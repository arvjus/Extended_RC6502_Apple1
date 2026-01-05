; Firmware of RC6502 Apple1 Replica
; Copyright (c) 2025 Arvid Juskaitis
;
; Test standard routines

*   = $1000
    jmp start

; WozMon locations
ECHO = $FFEF
PRBYTE= $FFDC

; ExtLib locations
CLEAR_SCREEN = $f900
SET_CURSOR_POS = $f903
SET_COLOR = $f906
PRINT_STR = $f909
PRINT_INT = $f90c
GET_CHAR = $f90f
GET_CHAR_NOWAIT = $f912
GET_STR = $f915
GET_INT = $f918
UINT2STR = $f91b
STR2UINT = $f922

start:

    ; ansi terminal
    jsr CLEAR_SCREEN
    
    lda   #10   ; row
    ldx   #3    ; col
    jsr   SET_CURSOR_POS

    lda   #34   ; dark blue
    jsr   SET_COLOR

    lda #<msg0
    ldx #>msg0
    jsr PRINT_STR

    lda   #37   ; white
    jsr   SET_COLOR

    ; conio - string
    lda #<msg1
    ldx #>msg1
    jsr PRINT_STR

    lda #<buff
    ldx #>buff
    ldy #10   ; max char
    jsr GET_STR
    
    lda #'>'
    jsr ECHO
    
    lda #<buff
    ldx #>buff
    jsr PRINT_STR

    ; conio - number
    lda #<msg2
    ldx #>msg2
    jsr PRINT_STR

    jsr GET_INT
    pha
    lda #'>'
    jsr ECHO
    pla
    
    jsr PRINT_INT
    
    lda #'.'
    jsr ECHO


; Exit to WozMon
exit:   jmp $ff00   ; WozMon

msg0:   .text   "it is blue", 0
msg1:   .text   13, "enter string:", 0
msg2:   .text   13, "enter number:", 0
buff:   .fill   12
