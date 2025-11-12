; serial communication program, using ACIA module

* = $0300  ; start address
    jmp start

KBD         = $D010         ;  PIA.A keyboard input
KBDCR       = $D011         ;  PIA.A keyboard control register
DSP         = $D012         ;  PIA.B display output register

PRBYTE = $FFDC

ACIA_CTRL   = $C000
ACIA_STATUS = $C000
ACIA_DATA   = $C001

start:
    ; Init ACIA
    lda #%00000011          ; $02 master reset
    sta ACIA_CTRL
    ;lda #%00010101          ; ($15) 115200 baud 8-n-1, no rx interrupt
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
    beq check_keyboard
    jsr print_char          ; Print it
    ;jsr PRBYTE
    ;lda #' '
    ;jsr print_char

check_keyboard:
    jsr KBDIN_NOWAIT        ; A = key or 0
    beq main_loop           ; Nothing pressed, loop again

    cmp #$1b                ; ESC
    beq exit

    jsr print_char          ; print_char key to screen

    ; --- Wait for TX ready ---
    pha
wait_tx_ready:
    lda ACIA_STATUS
    and #%00000010          ; Bit 1 = TDRE (transmit ready)
    beq wait_tx_ready

    pla
    sta ACIA_DATA           ; Send key over serial
    jmp main_loop

exit:
    lda #'.'
    jsr print_char
    jmp $ff00               ; WozMon

; print char placed in A
print_char:
    bit DSP                 ; DA bit (B7) cleared yet?
    bmi print_char          ; No, wait for display.
    sta DSP                 ; Output character. Sets DA.
    rts
    
 ; if char is available, return in A, otherwise return 0 in A
kbdin_nowait:
    lda KBDCR               ; is char available?
    bpl kbdin_nowait_none   ; not as long as bit 7 is low
    lda KBD     
    and #$7f                ; clear 7-nth bit
    rts
kbdin_nowait_none:
    lda #0
    rts
