; Firmware of RC6502 Apple1 Replica
; Copyright (c) 2025 Arvid Juskaitis

; Addresses within tmp_buffer
str2uint_buffer  = tmp_buffer     ; 6 bytes (buffer for input string)
str2uint_result  = tmp_buffer+6   ; 2 bytes (resulting number)
str2uint_temp    = tmp_buffer+8   ; 2 bytes temporary variable

; Convert ASCII string to str2uint_result (16-bit unsigned integer)
; Input:  str2uint_buffer (right-aligned, space-padded)
; Output: str2uint_result (16-bit number)
str2uint:
    cld                     ; Ensure decimal mode is off

    lda #0
    sta str2uint_result
    sta str2uint_result+1
    ldx #0
str2uint_loop:
    lda str2uint_buffer,x
    beq str2uint_end            ; null terminated
    cmp #'0'
    bcc str2uint_end            ; non-digit
    cmp #'9'+1
    bcs str2uint_end            ; non-digit

    pha
    jsr mul10
    pla

    sec
    sbc #'0'
    clc
    adc str2uint_result
    sta str2uint_result
    bcc str2uint_no_carry
    inc str2uint_result+1
str2uint_no_carry:
    inx
    cpx #5
    bne str2uint_loop
str2uint_end:
    rts

mul10:
    ; multiply current 16-bit value by 2, save in str2uint_temp
    asl str2uint_result
    rol str2uint_result+1
    lda str2uint_result
    sta str2uint_temp
    lda str2uint_result+1
    sta str2uint_temp+1

    ; now multiply the current 16-bit value by 4 more
    asl str2uint_result
    rol str2uint_result+1
    asl str2uint_result
    rol str2uint_result+1

    ; add partial (*2) to new value (*8) => result = *10
    clc
    lda str2uint_result
    adc str2uint_temp
    sta str2uint_result
    lda str2uint_result+1
    adc str2uint_temp+1
    sta str2uint_result+1
    rts
