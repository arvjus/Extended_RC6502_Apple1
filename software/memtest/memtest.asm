; program to test storage by filling memory and computing checksum

REAL_HW = 1

* = $002d
ptr:    .word ?

* = $0300  ; start address
    jmp start

    .include "system.asm"
start:
    ; print msg
    ldy #0
msg_loop:
    lda msg, y
    beq prn_addr
    jsr ECHO
    iny
    jmp msg_loop
prn_addr:
    ; print lower, upper addresses
    lda lower+1
    jsr PRBYTE
    lda lower
    jsr PRBYTE
    lda #'-'
    jsr ECHO
    lda upper+1
    jsr PRBYTE
    lda upper
    jsr PRBYTE
    lda #$0d        ; CR
    jsr ECHO

main_loop:
    jsr KBDIN
    cmp #'F'
    beq do_fill
    cmp #'C'
    beq do_checksum
    cmp #$1b        ; ESC
    beq exit
    jmp main_loop

exit:
    jmp $ff00       ; Wozmon

do_fill:
    jsr ECHO
    ; init ptr
    lda lower
    sta ptr
    lda lower+1
    sta ptr+1
    ; Start value
    ldx #$00        
fill_loop:
    txa
    ldy #$00
    sta (ptr),y
    inx
    ; next address
    inc ptr
    bne fill_skip_high  
    inc ptr+1
fill_skip_high:
    ; are we done?
    lda ptr+1
    cmp upper+1
    bne fill_loop
    lda ptr
    cmp upper
    bne fill_loop
    ; done
    lda #' '
    jsr ECHO
    jmp main_loop
    
do_checksum:
    jsr ECHO
    ; init ptr
    lda lower
    sta ptr
    lda lower+1
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
    cmp upper+1
    bne checksum_loop
    lda ptr
    cmp upper
    bne checksum_loop
    ; done, print result
    lda #' '
    jsr ECHO
    lda checksum+1
    jsr PRBYTE
    lda checksum
    jsr PRBYTE
    lda #' '
    jsr ECHO
    jmp main_loop

; data section
lower:      .addr $0500
upper:      .word $8000
checksum:   .word 0
msg:        .text 13, "Press F(ill), C(hecksum), in range (03E7)-(03E9): ", 0
