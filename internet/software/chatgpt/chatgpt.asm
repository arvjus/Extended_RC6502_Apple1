; chat program, using ACIA module

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
    lda #<chatgpt
    ldx #>chatgpt
    jsr PRINT_STR
    
main_loop:
    ; --- Check for serial input ---
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq check_keyboard
    lda ACIA_DATA           ; Get received char
    cmp #0
    beq check_keyboard
    cmp #$0a
    beq check_keyboard
    jsr ECHO                ; Print it

check_keyboard:
    lda KBDCR               ; is char available?
    bpl main_loop           ; not as long as bit 7 is low

    ; get the key and save it, send previous key if any
    lda KBD     
    and #$7f                ; clear 7-nth bit
    jsr ECHO
    cmp #$08                ; BS
    beq handle_bs
    cmp #$0d                ; CR
    beq handle_cr
    cmp #'#'
    beq handle_init
    tax
    lda last_key
    stx last_key
    cmp #0
    beq main_loop
    jsr transmit_char
    jmp main_loop

handle_bs:
    lda #0
    sta last_key
    jmp main_loop

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
    jmp main_loop

handle_init:
    lda #<init
    ldx #>init
    jsr transmit_str
    lda #<ready
    ldx #>ready
    jsr PRINT_STR
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


chatgpt:    .text   13, "ChatGPT, use #, !.., ..*", 13, 0
init:       .text   "!CLEAR", 13       
            .text   "!POST https://api.openai.com/v1/chat/completions", 13
            .text   "!HEAD Authorization: Bearer $(OPENAI-KEY)", 13
            .text   "!HEAD Content-Type: application/json", 13
            .text   "!BODY $(OPENAI-BODY)", 13
            .text   "!FILTER OPENAI-FILTER", 13, 0
ready:      .text   13, "READY", 13, 0
last_key:   .byte   0

