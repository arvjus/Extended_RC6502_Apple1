; Firmware of RC6502 Apple1 Replica
; Copyright (c) 2025 Arvid Juskaitis

*   = $FA00  ; start address

; CLEAR_SCREEN = $fa00
; SET_CURSOR_POS = $fa03
; SET_COLOR = $fa06
; PRINT_STR = $fa09
; PRINT_INT = $fa0c
; GET_CHAR = $fa0f
; GET_CHAR_NOWAIT = $fa12
; GET_STR = $fa15
; GET_INT = $fa18
; UINT2STR = $fa1b
; STR2UINT = $fa22

; usage:
; jsr   CLEAR_SCREEN
entry_clear_screen:
    jmp clear_screen

; usage:
; lda   #ROW    ; 1..30
; ldx   #COL    ; 1..90 
; jsr   SET_CURSOR_POS
entry_set_cursor_pos:
    jmp set_cursor_pos

; usage:
; lda   #COLOR
; jsr   SET_COLOR
;
; where COLOR is one of following:
; 30  - Black foreground
; 31  - Red foreground
; 32  - Dark Green foreground
; 33  - Dark Orange foreground
; 34  - Dark Blue foreground
; 35  - Magenta foreground
; 36  - Cyan foreground
; 37  - White foreground
; 40  - Black background
; 41  - Red background
; 42  - Dark Green background
; 43  - Dark Orange background
; 44  - Dark Blue background
; 45  - Magenta background
; 46  - Cyan background
; 47  - White background
; 92  - Medium Green foreground
; 93  - Bright Orange foreground
; 94  - Bright Blue foreground
; 95  - Bright Magenta foreground
; 96  - Bright Cyan foreground
; 102 - Medium Green background
; 103 - Bright Orange background
; 104 - Bright Blue background
; 105 - Bright Magenta background
; 106 - Bright Cyan background
entry_set_color:
    jmp set_color

; usage:
; lda #<str
; ldx #>str
; jsr PRINT_STR
entry_print_str:
    jmp print_str

; usage:
; lda #1    ; LSB
; ldx #0    ; MSB
; jsr PRINT_INT
entry_print_int:
    jmp print_int
    
; usage:
; jsr GET_CHAR
; A contains pressed key
entry_get_char:
    jmp KBDIN
    
; usage:
; jsr GET_CHAR_NOWAIT
; A contains pressed key or 0
entry_get_char_nowait:
    jmp KBDIN_NOWAIT
    
; usage:
; lda #<buffer
; ldx #>buffer
; ldy #10   ; max char
; jsr GET_STR
; A contains lenth of input string
entry_get_str:
    jmp get_str
    
; usage:
; A,X contains value
; jsr GET_INT
entry_get_int:
    jmp get_int        

; usage:
; lda   #LSB
; ldx   #MSB
; jsr   UINT2STR
;
; result $3e (6 bytes)
entry_uint2str:
    sta uint2str_number
    stx uint2str_number+1
    jmp uint2str

; usage:
; input str $3e (6 bytes max)
; jsr STR2UINT
;
; result A,X
entry_str2uint:
    jsr str2uint
    lda str2uint_result
    ldx str2uint_result+1
    rts

    .include "ansiterm.asm"
    .include "conio.asm"
    .include "uint2str.asm"
    .include "str2uint.asm"
