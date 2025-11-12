; matrix chat program, using ACIA module
; Copyright (c) 2025 Arvid Juskaitis	

* = $003e
tmp_buffer:         .fill 11  
ptr=tmp_buffer
tmp=tmp_buffer+2


* = $0300  ; start address

KBD         = $D010         ;  PIA.A keyboard input
KBDCR       = $D011         ;  PIA.A keyboard control register
DSP         = $D012         ;  PIA.B display output register

PRINT_STR = $fa09
PRINT_INT = $fa0c
GET_CHAR = $fa0f
GET_CHAR_NOWAIT = $fa12

PRBYTE = $FFDC
ECHO = $FFEF

ACIA_CTRL   = $C000
ACIA_STATUS = $C000
ACIA_DATA   = $C001

start:
    ; Init ACIA
    lda #%00000011          ; $02 master reset
    sta ACIA_CTRL
    lda #%00010110          ; ($16) 28800 baud 8-n-1, no rx interrupt
    sta ACIA_CTRL

    ; wait for 250ms
    lda #250
    jsr delay
    
    ; Welcome message    
    lda #<matrix
    ldx #>matrix
    jsr PRINT_STR
    
main_loop:    
    ; consume some incomming bytes, not required, just prevents register overrun
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq main_check_keyboard
    lda ACIA_DATA           ; Get received char
    
main_check_keyboard:
    lda KBDCR               ; is char available?
    bpl main_loop           ; not as long as bit 7 is low
    lda KBD     
    and #$7f                ; clear 7-nth bit
    and #$df                ; to upper-case
    jsr ECHO
    cmp #'R'
    beq handle_receive
    cmp #'M'
    beq handle_mark
    cmp #'X'
    beq handle_mark_reset
    cmp #'S'
    beq handle_send
    lda #<help              ; invalid command
    ldx #>help
    jsr PRINT_STR
    jmp main_loop

; receive and pring unread messages    
; ---------------------------------------------------------------
handle_receive:
    lda #$0d
    jsr ECHO
    ; setup variables for receiving
    lda #<receive
    ldx #>receive
    jsr transmit_str

    ldy #0                  ; Initialize index for position buffer
receive_line:    
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq receive_line
    lda ACIA_DATA           ; Get received char
    beq receive_done        ; Null terminator ends everything
    cmp #$0d                ; Check for CR
    beq line_complete
    cmp #$0a                ; Check for NL
    beq receive_line        ; Skip NL characters
    sta position,y          ; Store char in position buffer
    iny                     ; Move to next position
    jmp receive_line

line_complete:
    lda #$0d                ; CR
    sta position,y
    iny
    lda #0                  ; Null terminate the string
    sta position,y

receive_rest:
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq receive_rest_next
    lda ACIA_DATA           ; Get received char
    beq receive_done 
    cmp #$0a
    beq receive_rest_next
    jsr ECHO                ; Print it

receive_rest_next:
    jmp receive_rest    
receive_done:
    lda #$0d
    jsr ECHO
    lda #'>'
    jsr ECHO
    jmp main_loop

; reset position to zero
; ---------------------------------------------------------------
handle_mark_reset:
    lda #'&'
    sta position
    lda #$0d
    sta position+1
    lda #0
    sta position+2

; mark current chunk as read
; ---------------------------------------------------------------
handle_mark:
    jmp do_mark

; send a messge - text, terminated by CR
; ---------------------------------------------------------------
handle_send:
    lda #$0d
    jsr ECHO
    ; setup variables for sending
    lda #<send
    ldx #>send
    jsr transmit_str
   
send_loop:
    lda KBDCR               ; is char available?
    bpl send_loop           ; not as long as bit 7 is low

    ; get the key and save it, send previous key if any
    lda KBD     
    and #$7f                ; clear 7-nth bit
    cmp #$1b                ; ESC
    beq handle_esc
    jsr ECHO
    cmp #$08                ; BS
    beq handle_bs
    cmp #$0d                ; CR
    beq handle_cr
    tax
    lda last_key
    stx last_key
    cmp #0
    beq send_loop
    jsr transmit_char
    jmp send_loop

handle_esc:
    lda #<clear
    ldx #>clear
    jsr transmit_str
    lda #0
    sta last_key
    jmp send_done

handle_bs:
    lda #0
    sta last_key
    jmp send_loop

handle_cr:
    lda last_key
    cmp #0
    beq handle_cr_next
    jsr transmit_char
    lda #0
    sta last_key
handle_cr_next:
    lda #$0d                ; CR
    jsr transmit_char
send_done:    
    lda #$0d
    jsr ECHO
    lda #'>'
    jsr ECHO
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
    rts

; send mark command
; ---------------------------------------------------------------
do_mark:
    lda #$0d
    jsr ECHO
    lda #'>'
    jsr ECHO
    lda #<mark
    ldx #>mark
    jsr transmit_str
    jmp main_loop    

; transmit null- terminated string 
; A - LSB of str
; X - MSB of str
; ---------------------------------------------------------------
transmit_str:
    sta ptr
    stx ptr+1
transmit_str_loop:
    ldy #0
    lda (ptr), y
    beq transmit_str_done
    jsr transmit_char
    cmp #13
    bne transmit_str_next
    lda #100
    jsr delay
transmit_str_next:    
    inc ptr
    bne transmit_str_loop
    inc ptr+1
    jmp transmit_str_loop
transmit_str_done:
    rts

; X - delay value, one cycle - ~1ms (1038us)
; calling routine- adds 8us
delay:
	ldy #0          ; 2 cycles
delay_loop:
	iny             ; 2 cycles
	bne delay_loop  ; 2 cycles if branch taken, 3 if not taken
	dex             ; 2 cycles
	bne delay       ; 2 cycles if branch taken, 3 if not
	rts             ; 6 cycles


last_key:   .byte   0
matrix:     .text   13, "Matrix Chat"
help:       .text   13, "(R)eceive messages, (M)ark messages as read, (S)end a message", 13, '>', 0
receive:    .text   "!CLEAR", 13       
            .text   "!GET https://matrix.org/_matrix/client/v3/rooms/$(MATRIX-ROOM)/messages?"
            .text   "dir=f&limit=10&from=$(MATRIX-POSITION)", 13
            .text   "!HEAD Authorization: Bearer $(MATRIX-TOKEN)", 13
            .text   "!HEAD Content-Type: application/json", 13
            .text   "!FILTER MATRIX-FILTER", 13
            .text   "!SEND", 13, 0
send:       .text   "!CLEAR", 13       
            .text   "!PUT https://matrix.org/_matrix/client/v3/rooms/$(MATRIX-ROOM)/send/m.room.message/$(RANDOM)", 13
            .text   "!HEAD Authorization: Bearer $(MATRIX-TOKEN)", 13
            .text   "!HEAD Content-Type: application/json", 13
            .text   "!BODY $(MATRIX-BODY)", 13
            .text   "!FILTER SILENT-FILTER", 13, 0
clear:      .text   "*", 13, "!CLEAR", 13, 0
mark:       .text   "!SET MATRIX-POSITION "
position:   .text   0
