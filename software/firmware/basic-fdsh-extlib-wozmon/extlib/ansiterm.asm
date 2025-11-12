; Firmware of RC6502 Apple1 Replica
; Copyright (c) 2025 Arvid Juskaitis

; ANSI Sys terminal commands

; Zero-Page variables  
temp1 = tmp_buffer+8
temp2 = tmp_buffer+9

; "\033[2J"
clear_screen:
    jsr print_ansi_seq
    lda #'2'
    jsr ECHO
    lda #'J'
    jsr ECHO
    rts

; "\033[1;1H"
; A - row
; X - col
set_cursor_pos:
    sta temp1
    stx temp2
    lda #0          ; MSB is always 0
    sta uint2str_number+1
    jsr print_ansi_seq
    lda temp1       ; contains row positon
    sta uint2str_number
    jsr uint2str
    jsr print_uint2str_buffer
    lda #';'
    jsr ECHO
    lda temp2       ; contains column positon
    sta uint2str_number
    jsr uint2str
    jsr print_uint2str_buffer
    lda #'H'
    jsr ECHO
    rts

; "\033[30m"
; A- color
set_color:
    pha
    jsr print_ansi_seq
    pla             ; contains 30-106 color value
    sta uint2str_number
    jsr uint2str
    jsr print_uint2str_buffer
    lda #'m'
    jsr ECHO
    rts

print_ansi_seq:
    lda #$1b        ; ESC
    jsr ECHO
    lda #'['
    jsr ECHO
    rts

; skip spaces, print number
print_uint2str_buffer:
    ldx #2   
print_uint2str_buffer_skip_sp:
    lda uint2str_buffer, x
    cmp #' '
    bne print_uint2str_buffer_loop
    inx
    jmp print_uint2str_buffer_skip_sp
print_uint2str_buffer_loop:
    lda uint2str_buffer, x
    beq print_uint2str_buffer_done
    jsr ECHO
    inx
    jmp print_uint2str_buffer_loop
print_uint2str_buffer_done:
    rts

