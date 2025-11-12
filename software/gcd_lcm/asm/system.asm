; Implementation of GCD, LCM 
; Copyright (c) 2025 Arvid Juskaitis

; Char deffinitions
CR = $0D
ESC = $1B

.if REAL_HW     ;--------------------------------------

MOCK_HW = 0

; WozMon locations
ECHO = $FFEF
PRBYTE= $FFDC
KBD = $D010
KBDCR = $D011

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

; wait for char available, return in A
KBDIN:
    lda KBDCR   ; is char available?
    bpl KBDIN   ; not as long as bit 7 is low
    lda KBD     
    and #$7f    ; clear 7-nth bit
    rts

; if char is available, return in A, otherwise return 0 in A
KBDIN_NOWAIT:
    lda KBDCR   ; is char available?
    bpl KBDIN_NOWAIT_NONE   ; not as long as bit 7 is low
    lda KBD     
    and #$7f                ; clear 7-nth bit
    rts
KBDIN_NOWAIT_NONE:
    lda #0
    rts

.else   ; MOCK_HW ------------------------------------

MOCK_HW = 1

; we're running on py65mon, need to simulate some routines
PRBYTE: PHA             ; Save A for LSD.
        LSR
        LSR
        LSR             ; MSD to LSD position.
        LSR
        JSR PRHEX       ; Output hex digit.
        PLA             ; Restore A.
PRHEX:  AND #$0F        ; Mask LSD for hex print.
        ORA #'0'        ; Add "0".
        CMP #$3A        ; Digit?
        BCC ECHO        ; Yes, output it.
        ADC #$06        ; Add offset for letter.
ECHO:   STA $F001       ; PUTC
        RTS

; wait for char available, return in A
GET_CHAR:
KBDIN:  lda $f004       ; GETC
        beq KBDIN
        rts

; if char is available, return in A, otherwise return 0 in A
GET_CHAR_NOWAIT:
KBDIN_NOWAIT:
        lda $f004       ; GETC
        rts

CLEAR_SCREEN:   rts
SET_CURSOR_POS: rts
SET_COLOR:      rts

print_str_ptr=$46
PRINT_STR:      
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

PRINT_INT:
    pha
    txa         ; MSB
    jsr PRBYTE
    pla         ; LSB
    jsr PRBYTE
    rts

get_str_ptr=$46
get_str_tmp=$48
GET_STR:       
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


GET_INT:        rts
UINT2STR:       rts
STR2UINT:       rts

.endif  ; REAL_HW/MOCK_HW ----------------------------
