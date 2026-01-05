; program loader for ACIA module

; ACIA registers
ACIA_CTRL       = $c000
ACIA_STATUS     = $c000
ACIA_DATA       = $c001

.if FIRMWARE
* = $f800  ; start address
.else
; external routines
ECHO            = $ffef
PRBYTE          = $ffdc
PRINT_STR       = $f909
KBDIN           = $f90f
KBDIN_NOWAIT    = $f912

    .include "bss.asm"

* = $0300  ; start address
.endif

entry_loader:
loader:
    ; Init ACIA
    lda #%00000011          ; $02 master reset
    sta ACIA_CTRL
    ;lda #%00010101         ; $15 115200 baud 8-n-1
    lda #%00010110          ; $16 28800 baud 8-n-1
    sta ACIA_CTRL

    ; Init prg_start with WozMon
    lda #$00
    sta prg_start
    lda #$ff
    sta prg_start+1

main_loop:    
    ; Print message
    lda #<msg_wait
    ldx #>msg_wait
    jsr PRINT_STR
 
    ; Wait for keypress or transfer. If key pressed, run program if CR, exit otherwise
wait_for_cmd:
    jsr KBDIN_NOWAIT
    beq wait_for_trasfer    
    cmp #$0d                ; CR
    bne loader_exit
    jmp (prg_start)
wait_for_trasfer:    
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq wait_for_cmd    
    ; Receive 't' or 'r', store into variable
    jsr acia_rx_byte
    sta flag
    jsr ECHO

    ; Receive start/stop/ptr addresses
    jsr acia_rx_byte
    sta prg_start
    sta ptr
    jsr acia_rx_byte
    sta prg_start+1
    sta ptr+1
    lda #'.'
    jsr ECHO

    jsr acia_rx_byte
    sta prg_stop
    jsr acia_rx_byte
    sta prg_stop+1
    lda #'.'
    jsr ECHO

    ; Execute 'r', 't' commands
    lda flag
    cmp #'r'
    beq rx_tx
    cmp #'t'
    beq rx_tx
    jmp main_loop
    
loader_done:
    ; done
    lda #<msg_trdone
    ldx #>msg_trdone
    jsr PRINT_STR
 
    ; print start/stop addresses
    lda prg_start+1
    jsr PRBYTE
    lda prg_start
    jsr PRBYTE
    lda #'-'
    jsr ECHO
    lda prg_stop+1
    jsr PRBYTE
    lda prg_stop
    jsr PRBYTE

    ; checksum
    lda #<msg_chksm
    ldx #>msg_chksm
    jsr PRINT_STR
    jsr do_checksum
    jmp main_loop
    
loader_exit:
    lda #'.'
    jsr ECHO
    jmp $ff00               ; WozMon

; Receive bytes/store in address reange or read from address reange, transmit bytes
rx_tx:
    ldy #$00
    lda flag
    cmp #'r'
    beq rx_tx_receive
    ; TX
    lda (ptr),y
    jsr acia_tx_byte
    jmp rx_tx_next
rx_tx_receive:    
    ; RX
    jsr acia_rx_byte
    sta (ptr),y
rx_tx_next:
    ; next address
    inc ptr
    bne rx_tx_skip_high
    inc ptr+1
rx_tx_skip_high:
    ; are we done?
    lda ptr+1
    cmp prg_stop+1
    bne rx_tx
    lda ptr
    cmp prg_stop
    bne rx_tx
    jmp loader_done

; Wait for status flag, return byte in A
acia_rx_byte:
    lda ACIA_STATUS
    and #%00000001          ; Bit 0 = RDRF (data received)
    beq acia_rx_byte
    lda ACIA_DATA           ; Get received char
    rts

; Wait for status flag, send byte from A
acia_tx_byte:
    pha
acia_wait_tx_ready:
    lda ACIA_STATUS
    and #%00000010          ; Bit 1 = TDRE (transmit ready)
    beq acia_wait_tx_ready
    pla
    sta ACIA_DATA           ; Send byte over serial
    rts

; calculate 16-bit checksum for prg_start - prg_stop address range
do_checksum:
    ; init ptr
    lda prg_start
    sta ptr
    lda prg_start+1
    sta ptr+1
    ; zero checksum
    lda #0
    sta checksum
    sta checksum+1
checksum_loop:
    ldy #$00
    lda (ptr),y
    ; add A to checksum
    clc
    adc checksum
    sta checksum
    lda checksum+1
    adc #$00
    sta checksum+1
    ; next address
    inc ptr
    bne checksum_skip_high  
    inc ptr+1
checksum_skip_high:
    ; are we done?
    lda ptr+1
    cmp prg_stop+1
    bne checksum_loop
    lda ptr
    cmp prg_stop
    bne checksum_loop
    ; done, print result
    lda checksum+1
    jsr PRBYTE
    lda checksum
    jsr PRBYTE
    lda #$0d        ; CR
    jsr ECHO
    rts

msg_wait:   .text   13, "Waiting for transfer.. ", 0
msg_trdone: .text   " done.", 13, "Address range: ", 0
msg_chksm:  .text   ", checksum: ", 0
