; Firmware of RC6502 Apple1 Replica
; Copyright (c) 2025 Arvid Juskaitis

; A - LSB of str
; X - MSB of str
; ---------------------------------------------------------------
print_str_ptr=tmp_buffer+8
print_str:
    sta print_str_ptr
    stx print_str_ptr+1
print_str_loop:
    ldy #0
    lda (print_str_ptr), y
    beq print_str_done
    jsr ECHO
    inc print_str_ptr
    bne print_str_loop
    inc print_str_ptr+1
    jmp print_str_loop
print_str_done:
    rts

; A - LSB of value
; X - MSB of value
; ---------------------------------------------------------------
print_int:
	; convert
	sta uint2str_number
	stx uint2str_number+1
	jsr uint2str
	; print
	lda #<uint2str_buffer
	ldx #>uint2str_buffer
	jsr print_str
	rts
    
; Blocking, returns A - key pressed
; ---------------------------------------------------------------
KBDIN:
    lda $D011       ; Read KBDCR (bit 7 set if key available)
    bpl KBDIN       ; Loop until a key is available
    lda $D010       ; Read key
    and #$7F        ; Clear high bit
    rts             ; Return with character in A

; Non-blocking, returns 0 if no key available
; ---------------------------------------------------------------
KBDIN_NOWAIT:
    lda $D011       ; Read KBDCR
    bpl KBDIN_NOWAIT_none  ; If no key available, return 0
    lda $D010       ; Read key
    and #$7F        ; Clear high bit
    rts
KBDIN_NOWAIT_none:
    lda #0          ; Return 0 if no key
    rts

; A - LSB of buffer
; X - MSB of buffer
; Y - max len
; returns
; A - str len
; ---------------------------------------------------------------
get_str_ptr=tmp_buffer+8
get_str_tmp=tmp_buffer+10
get_str:
    sta get_str_ptr
    stx get_str_ptr+1
    sty get_str_tmp
    ldy #0
get_str_input:
    jsr KBDIN
    sta (get_str_ptr), y   ; Store character at target address
    cmp #$8                 ; BS
    beq get_str_input_back
    cmp #$1b                ; ESC
    beq get_str_exit
    cmp #$0d                ; CR
    beq get_str_done
    jsr ECHO
    cpy get_str_tmp
    beq get_str_done
    iny
    jmp get_str_input
get_str_input_back:
    jsr ECHO
    cpy #0                  ; If at beginning, do nothing
    beq get_str_input
    dey
    jmp get_str_input
get_str_exit:
    ldy #0                  ; Reset index
get_str_done:
    lda #0                  ; Replace CR with 0
    sta (get_str_ptr), y
    tya                     ; Return current index
	rts

; returns
; A - LSB of result
; X - MSB of result
; ---------------------------------------------------------------
get_int:
	lda #<str2uint_buffer
	ldx #>str2uint_buffer
	ldy #5 
	jsr get_str
	jsr str2uint
	lda str2uint_result
	ldx str2uint_result+1
	rts
