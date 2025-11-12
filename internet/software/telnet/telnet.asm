; telnet program, using ACIA module
; Copyright (c) 2025 Arvid Juskaitis	

* = $0300  ; start address

KBD         = $D010         ;  PIA.A keyboard input
KBDCR       = $D011         ;  PIA.A keyboard control register
DSP         = $D012         ;  PIA.B display output register

;PRBYTE = $FFDC

ACIA_CTRL   = $C000
ACIA_STATUS = $C000
ACIA_DATA   = $C001

start:
    ; Init ACIA
    lda #%00000011          ; $02 master reset
    sta ACIA_CTRL
    lda #%00010110          ; ($16) 28800 baud 8-n-1, no rx interrupt
    sta ACIA_CTRL
    
    lda #'$'
    jsr print_char

main_loop:
    ; --- Check for serial input ---
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq check_keyboard
    lda ACIA_DATA           ; Get received char
    cmp #$0a
    beq check_keyboard
    jsr print_char          ; Print it

check_keyboard:
    lda KBDCR               ; is char available?
    bpl main_loop           ; not as long as bit 7 is low

    ; get the key and send it
    lda KBD     
    and #$7f                ; clear 7-nth bit
    cmp #$0d                ; CR
    bne transmit
    jsr transmit_char
    lda #$0a                ; add LF
transmit:
    jsr transmit_char
    jmp main_loop

; transmit char placed in A
transmit_char:    
    pha
wait_tx_ready:
    lda ACIA_STATUS
    and #%00000010          ; Bit 1 = TDRE (transmit ready)
    beq wait_tx_ready
    pla
    sta ACIA_DATA           ; Send key over serial
    rt

; print char placed in A
print_char:
    bit DSP                 ; DA bit (B7) cleared yet?
    bmi print_char          ; No, wait for display.
    sta DSP                 ; Output character. Sets DA.
    jsr delay
    rts
    
delay:
    ldy 1
delay_loop:
    dey
    bne delay_loop    
    rts
