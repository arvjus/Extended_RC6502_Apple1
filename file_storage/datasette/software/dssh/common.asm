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
    jsr rx_byte
    jsr checksum_add
    clc                     ; TODO: handle timeout
    rts

; Receive Y bytes, store into buffer, X points to the next char in buffer
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


; Send byte from A, Handle XON/XOFF flow control
tx_byte:
    pha
    ; handle XON/XOFF
    lda ACIA_STATUS
    and #%00000001              ; Bit 0 = RDRF (data received)
    beq tx_byte_wait_ready
    lda ACIA_DATA               ; Get received char
    cmp #XOFF
    bne tx_byte_wait_ready
tx_byte_wait_xon:
    lda ACIA_STATUS
    and #%00000001              ; Bit 0 = RDRF (data received)
    beq tx_byte_wait_xon        ; TODO: handle timout
    lda ACIA_DATA               ; Get received char
    cmp #XON
    bne tx_byte_wait_xon
tx_byte_wait_ready:
    lda ACIA_STATUS
    and #%00000010              ; Bit 1 = TDRE (transmit ready)
    beq tx_byte_wait_ready
    pla
    sta ACIA_DATA               ; Send byte over serial
    clc                         ; TODO: handle timeout
    rts

; Send byte from A, no XON/XOFF flow control
tx_byte_no_fc:
    pha
tx_byte_no_fc_wait_ready:
    lda ACIA_STATUS
    and #%00000010              ; Bit 1 = TDRE (transmit ready)
    beq tx_byte_no_fc_wait_ready
    pla
    sta ACIA_DATA               ; Send byte over serial
    clc                         ; TODO: handle timeout
    rts

; Wait for status flag, send byte from A, add to checksum
tx_byte_checksum:
    jsr tx_byte
    jsr checksum_add
    clc                         ; TODO: handle timeout
    rts

; Send Y bytes, store into buffer, X points to the next char in buffer
tx_y_bytes_checksum:
    lda buffer, x
    jsr tx_byte_checksum
    bcs tx_y_bytes_checksum_err
    inx
    dey
    bne tx_y_bytes_checksum     ; not done yet? 
    clc                         ; success
    rts
tx_y_bytes_checksum_err:
    sec                         ; failure
    rts

; send a byte from A as two nibbles in hex
tx_byte_hex:
    pha     
    lsr                     ; Shift high nibble to low
    lsr
    lsr
    lsr
    jsr nibble_to_ascii
    jsr tx_byte             ; hi nibble 
    pla
    and #$0f                ; Mask out low nibble
    jsr nibble_to_ascii
    jsr tx_byte             ; lo nibble
    rts


; Bin -> hex
nibble_to_ascii:
    cmp #10          ; If >= 10, it's A-F
    bcc nibble_to_ascii_digit
    adc #6           ; Adjust for ASCII 'A'-'F'
nibble_to_ascii_digit:
    adc #$30         ; Convert to ASCII ('0'-'9' or 'A'-'F')
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

