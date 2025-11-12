; Implementation of GCD, LCM 
; Copyright (c) 2025 Arvid Juskaitis

; Set to 1=Apple1 or 0=py65mon
REAL_HW = 1
DEBUG = 0

NUM_MIN = 1
NUM_MAX = 100
PRINT_VALUES_HEX = 1

*   = $1000
    jmp start

    .include "system.asm"
    .include "mul.inc"
    .include "div.inc"

start:
    ; print char
    lda #'!'
    jsr ECHO

    ; init counter
    lda #0
    sta count
    sta count+1
        
    ; for a = NUM_MIN to NUM_MAX
    lda #NUM_MIN
    sta a
for_a_loop:
    cmp #NUM_MAX
    beq for_a_cont
    bcs for_a_break
for_a_cont:
    
    ; for b = a + 1 to NUM_MAX
    lda a
    clc
    adc #1
    sta b
for_b_loop:
    cmp #NUM_MAX
    beq for_b_cont
    bcs for_b_break
for_b_cont:
    
    ; calc GCD
    lda #0
    sta gcd_a+1
    sta gcd_b+1
    lda a
    sta gcd_a
    lda b
    sta gcd_b
    jsr gcd
    
    ; inc count if result is greater than 1
    lda gcd_a+1
    bne inc_count
    lda gcd_a
    cmp #1
    beq for_b_next
    
; continue, inc counter, calc LCM, print values    
inc_count:    
    inc count
    bne calc_lcm
    inc count+1
    
calc_lcm:
    jsr lcm     ; lcm = mul16_result

.if PRINT_VALUES_HEX
    jsr print_values
.endif    

    ; end for b
for_b_next:
    lda b
    clc
    adc #1
    sta b
    jmp for_b_loop
for_b_break:

    ; end for a
    lda a
    clc
    adc #1
    sta a
    jmp for_a_loop
for_a_break:
    
    ; print GCD in hex
    lda #'$'
    jsr ECHO
    lda count+1
    jsr PRBYTE
    lda count
    jsr PRBYTE

    lda #' '
    jsr ECHO

; Exit to WozMon
exit:
    jmp $ff00   ; WozMon

; Great Common Divisor
; while b != 0:
;    tmp = b
;    b = a % b
;    a = tmp
; return a
gcd:
    ; while
    lda gcd_b+1
    bne gcd_body
    lda gcd_b
    beq gcd_done
gcd_body:
    lda gcd_b
    pha
    lda gcd_b+1
    pha

    lda gcd_a
    sta div16_num1
    lda gcd_a+1
    sta div16_num1+1    

    lda gcd_b
    sta div16_num2
    lda gcd_b+1
    sta div16_num2+1

    jsr div16
    
    lda div16_rem
    sta gcd_b
    lda div16_rem+1
    sta gcd_b+1
    
    pla
    sta gcd_a+1
    pla 
    sta gcd_a

    jmp gcd
gcd_done:
    rts

; Least Common Multiply
; lcm = a / gcd(a, b) * b
lcm:
    lda a
    sta div16_num1
    lda #0
    sta div16_num1+1
    lda gcd_a
    sta div16_num2
    lda gcd_a+1
    sta div16_num2+1
    jsr div16
    
    lda div16_result
    sta mul16_num1
    lda div16_result+1
    sta mul16_num1+1
    lda b
    sta mul16_num2
    lda #0
    sta mul16_num2+1
    jsr mul16
    rts

; print values in hex
.if PRINT_VALUES_HEX
print_values:
    lda a
    jsr PRBYTE
    lda b
    jsr PRBYTE
    lda #'>'
    jsr ECHO
    lda gcd_a
    jsr PRBYTE
    lda #','
    jsr ECHO
    lda mul16_result+1
    jsr PRBYTE
    lda mul16_result
    jsr PRBYTE
    lda #' '
    jsr ECHO
    rts
.endif    

a:      .byte 0
b:      .byte 0
count:  .word 0
gcd_a:  .word 0
gcd_b:  .word 0

