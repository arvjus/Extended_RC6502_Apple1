    .setcpu "6502"

    .segment "E000"
    .include "a1basic.asm"

    .segment "F000"
    nop

    .segment "FE00"
    nop

    .segment "FF00"
    .include "wozmon.asm"

    .segment "VECTORS"
    ; Interrupt Vectors
    .WORD NMI            ; NMI
    .WORD RESET          ; RESET
    .WORD IRQ            ; BRK/IRQ
