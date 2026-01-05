; Datasette Shell
; Copyright (c) 2025 Arvid Juskaitis

; ------------------------------
; Macro SET_PTR addr
; parm1 - buffer
; ------------------------------
SET_PTR .macro
    lda #<\1
    sta ptr
    lda #>\1
    sta ptr+1
    .endm

; ptr has to be set befor enter this
print_msg:
    ldy #0
print_msg_loop:
    lda (ptr), y
    beq print_msg_done
    jsr ECHO
    iny
    jmp print_msg_loop
print_msg_done:
    rts

; print address range - execution time is 44mS
print_start_stop:
    lda prg_start+1             ; start high
    jsr PRBYTE
    lda prg_start               ; start low
    jsr PRBYTE
    lda #' '
    jsr ECHO
    lda #'-'
    jsr ECHO
    lda #' '
    jsr ECHO
    lda prg_stop+1              ; stop high
    jsr PRBYTE          
    lda prg_stop                ; stop low
    jsr PRBYTE
    lda #' '
    jsr ECHO
    rts

; Convert ASCII hex character to binary nibble (0-15)
hex_to_bin:
    cmp #$30            ; '0'
    bcc invalid_hex
    cmp #$3a            ; '9' + 1
    bcc is_digit
    cmp #$41            ; 'A'
    bcc invalid_hex
    cmp #$47            ; 'F' + 1
    bcs invalid_hex
    sec                 ; Set carry before SBC
    sbc #$37            ; convert 'A'-'F' -> 10-15
    rts
is_digit:
    sec                 ; Set carry before SBC
    sbc #$30            ; convert '0'-'9' -> 0-9
    rts
invalid_hex:
    lda #$00            ; return 0 if invalid
    rts

; Receive byte, return byte in A
rx_byte:
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq rx_byte
    lda ACIA_DATA           ; Get received char
    clc                     ; TODO: handle timeout
    rts

; Receive byte, update checksum, return byte in A
rx_byte_checksum:
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq rx_byte_checksum
    lda ACIA_DATA           ; Get received char
    jsr checksum_add
    clc                     ; TODO: handle timeout
    rts

; receive first Y bytes, store into buffer, X points to the next char in buffer
rx_y_bytes_checksum:
    jsr rx_byte_checksum
    bcs rx_y_bytes_checksum_err
    sta buffer, x
    inx
    dey
    bne rx_y_bytes_checksum     ; not done yet? 
    clc                         ; success
    rts
rx_y_bytes_checksum_err:
    sec                         ; failure
    rts


; Wait for status flag, send byte from A
tx_byte:
    pha
wait_tx_ready:
    lda ACIA_STATUS
    and #%00000010          ; Bit 1 = TDRE (transmit ready)
    beq wait_tx_ready
    pla
    sta ACIA_DATA           ; Send byte over serial
    clc                     ; TODO: handle timeout
    rts

; zero checksum
checksum_init:
    lda #0
    sta checksum
    sta checksum+1
    rts

; add A to checksum
checksum_add:
    pha
    clc
    adc checksum
    sta checksum
    lda checksum+1
    adc #$00
    sta checksum+1
    pla
    rts

