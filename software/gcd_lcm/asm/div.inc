;
; Copyright (c) 2023, Arvid Juskaitis (arvydas.juskaitis@gmail.com)
;
; Division functions
; Inspired by https://llx.com/Neil/a2/mult.html
; 64tass dialect
;

; Func. div16
; Returns result in div16_num1
div16
    lda #0              ; initialize REM to 0
    sta div16_rem
    sta div16_rem+1

    ldx #16             ; there are 16 bits in NUM1
div16_loop
    asl div16_num1      ; shift hi bit of NUM1 into REM
    rol div16_num1+1    ; (vacating the lo bit, which will be used for the quotient)
    rol div16_rem
    rol div16_rem+1
    lda div16_rem
    sec                 ; trial subtraction
    sbc div16_num2
    tay
    lda div16_rem+1
    sbc div16_num2+1
    bcc div16_skip      ; did subtraction succeed?
    sta div16_rem+1     ; yes, save it
    sty div16_rem
    inc div16_num1      ; and record a 1 in the quotient
div16_skip
    dex
    bne div16_loop
    rts

div16_result
div16_num1  .word 0
div16_num2  .word 0
div16_rem   .word 0

